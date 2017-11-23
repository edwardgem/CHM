//
//	Copyright (c) 2006, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: IndexBuilder.java
//	Author: AGQ
//	Date:	06/16/06
//	Description: Search engine builds an index of attachment objects.
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
package mod.se;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.nio.file.FileSystems;
import java.util.ArrayList;
import java.util.HashMap;

import mod.se.filehandler.Handler;
import mod.se.filehandler.HandlerZIP;
import oct.codegen.attachment;
import oct.codegen.attachmentManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;
import org.apache.lucene.analysis.standard.StandardAnalyzer;
import org.apache.lucene.document.Document;
import org.apache.lucene.document.Field;
import org.apache.lucene.document.TextField;
import org.apache.lucene.index.IndexWriter;
import org.apache.lucene.index.IndexWriterConfig;
import org.apache.lucene.index.Term;
import org.apache.lucene.store.Directory;
import org.apache.lucene.store.FSDirectory;

import util.PrmLog;
import util.Util;

public class IndexBuilder {
	static Directory indexDir;
	static final String indexDirS = Util.getPropKey(SEConstants.PST, SEConstants.SE_INDEX_PATH);
	static final String repository = Util.getPropKey(SEConstants.PST, SEConstants.FILE_UPLOAD_PATH);
	static final String removeAtt = Util.getPropKey(SEConstants.PST, "REMOVE_ATT_OBJ");
	static final boolean bRemoveAttObj = (removeAtt!=null && removeAtt.equalsIgnoreCase("true"))?true:false;
	static final String IGNORE_TYPE = ".mp3.MP3.jpg.JPG.gif.GIF.bmp.BMP";
	
	static IndexWriter idxWriter;

	//static final String prefix = Util.getPropKey(SEConstants.PST, SEConstants.SE_INDEX_PATH);
	static attachmentManager attachmentMgr = null;
	static HashMap<String, String> hashmap = null;
	static Logger l = PrmLog.getLog();
	
	static {
		createIgnoreMap();
	}

	public static Directory getIndexDir() {
		return indexDir;
	}

	public static String getIndexDirS() {
		if (indexDirS == null)
			return "";
		return indexDirS;
	}
	
	public static IndexWriter getIndexWriter() {
		if (idxWriter!=null && !idxWriter.isOpen())
			idxWriter = null;
		
		if (idxWriter == null) {
			// initialize indexWriter
			StandardAnalyzer analyzer = new StandardAnalyzer();
			IndexWriterConfig config = new IndexWriterConfig(analyzer);
			try {
				indexDir = FSDirectory.open(FileSystems.getDefault().getPath(indexDirS));
				idxWriter = new IndexWriter(indexDir, config);
			}
			catch (IOException e) {e.printStackTrace();}
		}
		return idxWriter;
	}
	
	public static void closeWriter() {
		try {idxWriter.close();}
		catch (IOException e) {}
		idxWriter = null;
	}

	/**
	 * Checks to see if it is currently in use. Deletes
	 * the current index and build a new one from scratch.
	 * If rebuild is false then index will only be built if none exist
	 * @param rebuild
	 */
	public static boolean build(PstUserAbstractObject pstuser, boolean rebuild) {
		// builds a new index
		getIndexWriter();
		
		try {
			if (!IndexStatus.isCurrentlyUsed()) {
				File dir = new File(indexDirS);
				if (rebuild) {
					if (dir.exists())
						dir.delete();
				}
				else {
					if (dir.exists())
						return false;
				}

				if (attachmentMgr == null)
					attachmentMgr = attachmentManager.getInstance();
				PstAbstractObject[] objArr = attachmentMgr.getAllattachment(pstuser);

				// Debug specific file during index
				//int[] intArr = attachmentMgr.findId(pstuser, "Location='/69775/soft_mtx_data.zip'");
				//PstAbstractObject[] objArr = attachmentMgr.get(pstuser, intArr);

				IndexStatus.setCurrentlyUsed(true);
				String ext;
				int idx;
				
				// need to loop through all the repository files from database
				for (int i=0; i<objArr.length; i++) {
					attachment att = (attachment)objArr[i];
					int id = att.getObjectId();
					Object obj = att.getAttribute(attachment.LOCATION)[0];
					String relativePath = (obj!=null)?(String)obj:null;
					if (relativePath == null) {
						l.error("Attachment object id: " + id + " does not contain " + attachment.LOCATION);
						if (bRemoveAttObj) attachmentMgr.delete(att);	//delete(null, String.valueOf(id));
						continue;
					}
					String fileLocation = relativePath;
					System.out.println("***CurrentFile : " + fileLocation);
					idx = fileLocation.lastIndexOf('.');
					if (idx != -1)
					{
						ext = fileLocation.substring(idx);
						if (hashmap.containsKey(ext))
						{
							System.out.println("Ignore file: " + fileLocation);
							continue;
						}
					}

					ArrayList <Document> docArr = indexDocument(fileLocation, String.valueOf(id));
					if (docArr.size()<=0 && bRemoveAttObj)
						attachmentMgr.delete(att);

					try {
						for (int j=0; j<docArr.size(); j++) {
							Object tempObj = docArr.get(j);
							if (tempObj == null) continue;
							Document doc = (Document)tempObj;
							idxWriter.addDocument(doc);
						}
					} catch (IOException e) {
						l.error(e);
					}
				}
				//writer.optimize();		// ECC: no need for Lucene 6.2
				IndexStatus.setOptimized(true);
				idxWriter.commit();
				closeWriter();
				return true;
			}
			else
				return false;
		} catch (IOException e) {
			l.error(e);
			return false;
		} catch (PmpException e) {
			l.error(e);
			return false;
		} finally {
			if (idxWriter != null)
				closeWriter();
			IndexStatus.setCurrentlyUsed(false);
		}
	}

	/**
	 * Deletes the current document from the index and also the cache file
	 * @param id
	 * @return
	 */
	public static boolean delete(String fileLocation, String id) {
		IndexWriter writer = getIndexWriter();
		//IndexModifier modifier = null;
		try {
			System.out.println("*** IndexBuilder.delete() CurrentFile : " + fileLocation);
			int idx = fileLocation.lastIndexOf('.');
			if (idx != -1)
			{
				String ext = fileLocation.substring(idx);
				if (hashmap.containsKey(ext))
				{
					System.out.println("Ignore file: " + fileLocation);
					return false;
				}
			}
			IndexStatus.setCurrentlyUsed(true);
			if (fileLocation != null)
				deleteCacheFile(fileLocation);
			//modifier = new IndexModifier(indexDir, new StandardAnalyzer(), false);
			Term term = new Term(SEConstants.ID, id);
			long affected = writer.deleteDocuments(term);	// return sequence no.
			
			//int affected = modifier.deleteDocuments(term);
			//modifier.flush();
			//modifier.close();
			writer.commit();
			//closeWriter();		// ECC: in update() after delete I am going to add
			IndexStatus.setCurrentlyUsed(false);
			l.debug(affected + " items deleted");
			if (affected > 0) {
				IndexStatus.setUpdated(true);
				IndexStatus.setOptimized(false);
				new IndexScheduler(IndexScheduler.RELOAD).start();
				return true;
			}
			else
				return false;
		} catch (IOException e) {
			l.error(e);
/*			try {
				if (modifier != null) {
					modifier.flush();
					modifier.close();
				}

			} catch (IOException f) {}
*/
			closeWriter();
			IndexStatus.setCurrentlyUsed(false);
			return false;
		}
	}

	/**
	 * Delete any existing file with the same file name from the index.
	 * Indexes the current file and sets the status to updated and
	 * requires optimization
	 * @param id
	 * @return true when successful; otherwise false
	 */
	public synchronized static boolean update(String fileLocation, String id) {
		//IndexModifier modifier = null;
		IndexWriter writer = getIndexWriter();

		try {
			System.out.println("*** IndexBuilder.update() CurrentFile : " + fileLocation);
			int idx = fileLocation.lastIndexOf('.');
			if (idx != -1)
			{
				String ext = fileLocation.substring(idx);
				if (hashmap.containsKey(ext))
				{
					System.out.println("Ignore file: " + fileLocation);
					return false;
				}
			}

			// delete the old index and file first
			boolean isUpdate = delete(fileLocation, id);
			IndexStatus.setCurrentlyUsed(true);
			
			
			//modifier = new IndexModifier(indexDir, new StandardAnalyzer(), false);
			ArrayList <Document> docArr = indexDocument(fileLocation, id);

			for (int i=0; i<docArr.size(); i++) {
				Object tempObj = docArr.get(i);
				if (tempObj == null) continue;
				Document doc = (Document)tempObj;
				writer.addDocument(doc);
				//modifier.addDocument(doc);
			}

			
			writer.commit();
			closeWriter();
			IndexStatus.setCurrentlyUsed(false);
			if (docArr != null) {
				if (!isUpdate) {
					IndexStatus.setUpdated(true);
					IndexStatus.setOptimized(false);
				}
			}
			new IndexScheduler(IndexScheduler.RELOAD).start();
			return true;
		} catch (IOException e) {
			l.error(e);
/*			if (modifier != null) {
				try {
					modifier.close();
				} catch (IOException ioe) {}
			}
*/
			closeWriter();
			IndexStatus.setCurrentlyUsed(false);
			return false;
		}
	}

//***************************
//* Private Methods
//***************************

	private static ArrayList<Document> addAllFiles(File file, String id) {
		ArrayList <Document> docArr = new ArrayList <Document> ();
		if (file.canRead()) {
			if (file.isDirectory()) {
				File [] fList = file.listFiles();
				if (fList != null)
				{
					for (int i=0; i<fList.length; i++) {
						docArr.addAll(addAllFiles(fList[i], id));
					}
				}
			} else {
				docArr.addAll(indexDocument(file.getAbsolutePath(), id));
			}
		}

		return docArr;
	}

	/**
	 * Create cache file for contents
	 * @param fileLocation
	 * @param fileContents
	 * @return
	 */
	private static boolean createFile(String fileLocation, String fileContents) {
		OutputStreamWriter out = null;
		try {
	    	String cachePath = mod.se.Util.createCachePath(fileLocation);

	    	int forwardIdx = cachePath.lastIndexOf("/");
	    	int backwardIdx = cachePath.lastIndexOf("\\");
	    	int pathIdx = (forwardIdx>backwardIdx)?forwardIdx:backwardIdx;

			String path = (pathIdx != -1)?cachePath.substring(0, pathIdx):"";
			new File(path).mkdirs();
			File file = new File(cachePath);
			if (file.exists())
				file.delete();
			// Create file if it does not exist
			boolean success = file.createNewFile();
			if (success) {
				FileOutputStream fos = new FileOutputStream(file);
				out = new OutputStreamWriter(fos, "UTF-8");
				out.write(fileContents.replaceAll("\n", " "));
				out.flush();
				out.close();
				out = null;
				return true;
			} else {
				l.error("Previous file was unable to be deleted: " + cachePath);
				return false;
			}
		} catch (IOException e) {
			l.error(e);
			return false;
	    } finally {
	    	try {
		    	if (out != null) {
		    		out.flush();
		    		out.close();
		    	}
	    	} catch (IOException f) {}
	    }
	}

	private static void createIgnoreMap() {
		if (hashmap == null) {
			hashmap = new HashMap <String, String> ();
			for (int i=0; i<SEConstants.IGNOREEXT.length; i++) {
				hashmap.put(SEConstants.IGNOREEXT[i], SEConstants.IGNOREEXT[i]);
			}
		}
	}

	private static boolean deleteAllFiles(File file) {
		if (file.canRead()) {
			if (file.isDirectory()) {
				File [] fList = file.listFiles();
				if (fList != null)
				{
					for (int i=0; i<fList.length; i++) {
						deleteAllFiles(fList[i]);
					}
				}
			}
		}
		file.delete();
		return true;
	}


	private static boolean deleteCacheFile(String fileLocation) {
		try {
			if (fileLocation!=null && fileLocation.length()>0) {
				String cachePath = mod.se.Util.createCachePath(fileLocation);
				File file = new File(cachePath);
				if (file.exists()) {
					if(!file.delete())
						throw new IOException();
				}
				return true;
			}
			return false;
		} catch (IOException e) {
			l.error(e);
			return false;
		}
	}

	/**
	 * Determines which file type this belongs to and extracts
	 * all the required text into Lucene’s Document class. Saves
	 * the contents into an individual cached file and performs
	 * an add document onto the index.
	 * @param fileLocation
	 * @return
	 */
	private static ArrayList <Document> indexDocument(String fileLocation, String id) {
		ArrayList <Document>  docArr = new ArrayList<Document>();
		String absolutePath;
		fileLocation = fileLocation.replaceAll("\\\\", "/");

		if (Util.isAbsolutePath(fileLocation))
			absolutePath = fileLocation;
		else
			absolutePath = repository + fileLocation;

		Handler handler = mod.se.Util.getFileType(absolutePath);
		String extension = handler.getExt();

		try {
			// Zip file
			if (extension != null && extension.equals(SEConstants.ZIP)) {
				HandlerZIP handlerZIP = (HandlerZIP) handler;
				handlerZIP.extractInfo();
				String directory = handlerZIP.getDirectory();
				handlerZIP = null;
				if (directory != null) {
					File file = new File(directory);
	
					docArr.addAll(addAllFiles(file, id));
	
					// Remove all the extracted files
					deleteAllFiles(file);
				}
			}
			else {
				String contents = null;
				// Handle Ignore File Types
				if (hashmap == null) {
					createIgnoreMap();
				}
	
				if (extension == null || !hashmap.containsKey(extension)) {
					if (!handler.extractInfo())
						return docArr;
					contents = handler.getContents();
				}
				else {
					contents = " ";
				}
	
				if (contents != null) {
					Document doc = new Document();
					String fname = fileLocation.substring(fileLocation.lastIndexOf("/")+1).trim().toLowerCase();
//					doc.add(new Field(SEConstants.CONTENTS, contents, Field.Store.NO, Field.Index.TOKENIZED));
//					doc.add(new Field(SEConstants.ID, id, Field.Store.YES, Field.Index.UN_TOKENIZED));
//					doc.add(new Field(SEConstants.PATH, fileLocation, Field.Store.YES, Field.Index.TOKENIZED));
//					doc.add(new Field(SEConstants.FILENAME, fname, Field.Store.NO, Field.Index.UN_TOKENIZED));
					
System.out.println("---- index filename: " + fname);
					File file = new File(absolutePath);
					doc.add(new Field(SEConstants.FILENAME, fname, TextField.TYPE_STORED));
					doc.add(new Field(SEConstants.ID, id, TextField.TYPE_STORED));
					doc.add(new Field(SEConstants.PATH, fileLocation, TextField.TYPE_STORED));
					doc.add(new Field(SEConstants.CONTENTS, contents, TextField.TYPE_NOT_STORED));
/*					doc.add(new Field(SEConstants.CONTENTS,
							new InputStreamReader(new FileInputStream(file), "utf-8"),
							TextField.TYPE_NOT_STORED));
*/					
					if (createFile(fileLocation, contents))
						docArr.add(doc);
					return docArr;
				}
				else
					return docArr;
			}
		}
		catch (Exception e) {
			// if I failed in handling one document, I just log it and keep going
			// e.g. I might die just because the file is too big and I run out of
			// memory
			String msg = e.getMessage();
			l.warn("Failed indexing document [" + absolutePath + "]\n"
					+ msg);
			e.printStackTrace();
		}
		
		return docArr;
	}
}
