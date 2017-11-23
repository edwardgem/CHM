//
//	Copyright (c) 2007, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	FileTransfer.java
//	Author:	ECC
//	Date:	04/03/05
//	Description:	 This object take care of file upload and download in Pst
//
//	Modification:
//		@AGQ033106	Modified sending files to client through streaming instead of reading the
//					whole file all at once. 
//		@061306ECC	Support attachment object type.
//		@AGQ061606	Removed attachment using replace method since not all file 
//					has Attachment- text and ID may become longer
//		@AGQ062706	Constructs the absolutePath for the given fileName
//					or returns the fileName if it is already an absolutePath
//		@ECC050207 Upload file size limit
//
/////////////////////////////////////////////////////////////////////
//
// FileTransfer.java : implementation of the PmpFileTransfer class
//
package oct.util.file;

import java.awt.Container;
import java.awt.Graphics2D;
import java.awt.Image;
import java.awt.MediaTracker;
import java.awt.RenderingHints;
import java.awt.Toolkit;
import java.awt.image.BufferedImage;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FilenameFilter;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.Date;
import java.util.ResourceBundle;

import oct.codegen.attachment;
import oct.codegen.attachmentManager;
import oct.omm.client.OmsAttribDef;
import oct.omm.client.OmsMember;
import oct.omm.client.OmsOrganization;
import oct.omm.client.OmsSession;
import oct.omm.common.OmsException;
import oct.pmp.exception.PmpException;
import oct.pmp.exception.PmpInternalException;
import oct.pmp.exception.PmpInvalidAttributeException;
import oct.pmp.exception.PmpUnsupportedTypeException;
import oct.pst.PstAbstractObject;
import oct.pst.PstUserAbstractObject;
import oct.util.file.exception.FileTransferException;

import org.apache.log4j.Logger;

import util.PrmLog;
import util.Util;
import util.Util3;

import com.sun.image.codec.jpeg.JPEGCodec;
import com.sun.image.codec.jpeg.JPEGEncodeParam;
import com.sun.image.codec.jpeg.JPEGImageEncoder;

/**
 * The FileTransfer class
 * 	General Description: This class handles File upload / download.  It should not be
 *	use directly by user but servlet that handles files.
 *
 *	Miscellaneous :
 *
 * @version $version$
 */
public class FileTransfer
{
	static Logger l;

	//private final static String CONFIG_NAME = "omm";
	private static String FILE_CONFIG_NAME = "pst";
	private final static String FILE_PATH = "FILE_UPLOAD_PATH";
	private final static String SHOW_FILE_PATH = "SHOW_FILE_PATH";
	private final static String URL_FILE_PATH = "URL_FILE_PATH";
	private final static String ARCV_FILE_PATH = "ARCHIVE_PATH";
	private final static String USER_PIC_FILE_PATH = "USER_PICFILE_PATH";
	private final static String USER_PIC_FILE_URL = "USER_PICFILE_URL";
	private final static String UPLOAD_FILE_SIZE_LIMIT = "MAX_UPLOAD_SIZE";
	private final static String DEBUG_FLAG = "DEBUG_FLAG";
	private final static String IMAGE_EXT	= "gif;jpg;jpeg;png";

	private final static long	ONE_MEG = 1048576;
	private final static long	IMG_FSIZE_LIMIT		= 500 * 1024;	// img file size limit to 300K
	private final static long	ICON_FSIZE_LIMIT	= 100 * 1024;	// icon file size for user face
	
	private final static int	DEFAULT_PIC_WIDTH	= 400;
	private final static int	DEFAULT_PIC_HEIGHT	= 400;
	private final static int	DEFAULT_PIC_QUALITY	= 500;
	
	private static attachmentManager attMgr = null;

	public OmsSession sess = null;
	public PstUserAbstractObject thisUser = null;
	public String URLname = "";
	public String storagePath = "";
	public String showFilePath = "";
	public String arcvFilePath = "";
	public String debug_level = "";
	private static int debug = 0;
	private long uploadSizeLimit = 0;	// in bytes
	
	public String picFileStoragePath = "";
	public String picFileURL = "";
	
	static
	{
		try
		{
			l = PrmLog.getLog();
			attMgr = attachmentManager.getInstance();
		}
		catch (PmpException e){}
	}
	
	public FileTransfer(PstUserAbstractObject u)
		throws PmpException
	{
		this(u.getSession(), null);
		thisUser = u;
	}

	public FileTransfer(OmsSession session, String configFileName)
	{
		this.sess = session;
		if (configFileName != null)
			FILE_CONFIG_NAME = configFileName;		// so that I can use JW.properties

		//Read config file for temp path
		//ResourceBundle bundleFile = ResourceBundle.getBundle(CONFIG_NAME);
		ResourceBundle filebundleFile = ResourceBundle.getBundle(FILE_CONFIG_NAME);
		this.URLname = filebundleFile.getString(URL_FILE_PATH);
		this.storagePath = filebundleFile.getString(FILE_PATH);
		this.showFilePath = filebundleFile.getString(SHOW_FILE_PATH);
		this.arcvFilePath = filebundleFile.getString(ARCV_FILE_PATH);
		this.picFileStoragePath = filebundleFile.getString(USER_PIC_FILE_PATH);
		this.picFileURL = filebundleFile.getString(USER_PIC_FILE_URL);
		
		String s = Util.getPropKey(FILE_CONFIG_NAME, UPLOAD_FILE_SIZE_LIMIT);
		if (s != null)
			uploadSizeLimit = Long.parseLong(s);
		
		try
		{
			// debug_level = bundleFile.getString(DEBUG_FLAG);
			debug_level = filebundleFile.getString(DEBUG_FLAG);
		}
		catch(Exception e)
		{
			debug_level = "0";
		}
		debug = Integer.parseInt(debug_level);
		if (debug > 1)
		{
			l.info("(" + session.getOmsUser().getUserName() + ") Inside FileTransfer:");
			//l.info("storagePath:" + storagePath);
		}
	}

	/**
	* Set the attribute of the object with binary content from the file dowloaded
	* @param objectName - The Name of the object to be accessed.
	* @param org - The OmsOrganization of the object to be accessed.
	* @param attribute - The attribute to be set
	* @param contentFile - The java.io.file object which content will be read and set
	*					   into the object specified by the Id
	* @exception PmpUnsupportedTypeException - The attribute specified does not support raw data type
	* @exception PmpInvalidAttributeException - The object does not contain the attribute specified
	* @exception IOException - File reading error.
	* @exception PmpInternalException - Internal error.
	*/
/*	public void setAttributeValueWithFile(String objectName, OmsOrganization org, String attribute, File contentFile)
		throws FileTransferException, FileNotFoundException, IOException
	{
		OmsMember member = null;
		OmsAttribDef attDef = null;
		try
		{
			member = new OmsMember(this.sess, org, objectName);
		}
		catch(OmsException e)
		{
			e.printStackTrace();
			throw new FileTransferException("Cannot instantiate member. " + e.toString());
		}

		try
		{
			attDef = new OmsAttribDef(this.sess, attribute);
		}
		catch(OmsException e)
		{
			throw new FileTransferException("Cannot retrieve attribute definition. " + e.toString());
		}
		int type = attDef.getType();

		//If the attribute type is raw, read the file and set it into the object itself
		if(type == OmsAttribDef.OMS_RAW)
		{
			final int contentFileSize = (int)contentFile.length();
			if (debug > 1)
			{
				System.out.println("Get save File: " + attribute);
				System.out.println("contentFile abs. path :" + contentFile.getAbsolutePath());
				System.out.println("File size is:" + contentFileSize);
			}
			FileInputStream contentInput = new FileInputStream(contentFile);
			byte contentBuf[] = new byte[contentFileSize];
			int readSize = contentInput.read(contentBuf);
			if (readSize != contentFileSize)
			{
				System.out.println("Caution!! content file size is :" + contentFileSize + " and readSize is :" + readSize);
			}
			try
			{
				member.setRaw(attribute, contentBuf);
				member.setAttValue();
			}
			catch(OmsException e)
			{
				throw new FileTransferException("Cannot save the content into object. " + e.toString());
			}

        }
		//else if the attribute is string, verify the sub-directory that belongs to the object
		//copy the file into that sub-directory and set the attribute to be the file name
		else if (type == OmsAttribDef.OMS_STRING)
		{
        	//First figure out the file name for this content file.  Additional operation is
        	//performed to ensure uniqueness of the file name.
        	//The file name will be <default path>/<object Id>/<attribute>-<originalfilename>
        	String contentOriginalName = contentFile.getName();
        	String newContentFileName = attribute + "-" + contentOriginalName;

        	String outputFileName = objectName + "_" + org.getName() + "/" + newContentFileName;
        	String absoluteOutputFileName = storagePath + "/" + objectName + "_" + org.getName() + "/" + newContentFileName;
			if (debug > 1)
			{
				System.out.println("Get save File: " + attribute);
				System.out.println("contentOriginalName :" + contentOriginalName);
				System.out.println("newContentFileName :" + newContentFileName);
				System.out.println("outputFileName :" + outputFileName);
				System.out.println("absoluteOutputFileName :" + absoluteOutputFileName);
			}
			//Check to see if the object sub-directory is ready or not
			String subDirStr = storagePath + File.separator + objectName + "_" + org.getName();
			File subDirectory = new File(subDirStr);

			//If not exist, create it.
			if(!subDirectory.exists())
				subDirectory.mkdirs();

        	//Start the read/write operation
        	FileOutputStream localFile = new FileOutputStream(absoluteOutputFileName);
        	FileInputStream fis = new FileInputStream(contentFile);

        	final int bufferNum = 8192;
			byte buf[] = new byte[bufferNum];
			int len = 0;

			while (len != -1)
			{
				len = fis.read(buf, 0, bufferNum);
				if (len == -1)
					break;

				localFile.write(buf, 0, len);
			}

			fis.close();
			localFile.flush();
			localFile.close();

			//Set the attribute to be the file path.  We only storage the relative path because
			//in case admin move the storage to anyother place this attribute value will still
			//be valid.
			try
			{
				member.setStringAttrib(attribute, outputFileName, false);
				member.setAttValue();
			}
			catch(OmsException e)
			{
				throw new FileTransferException("Cannot save the content into object. " + e.toString());
			}

		}
		//else, throw an exception
		else
		{
			throw new FileTransferException("Attribute " + attribute + " is not of type Raw or String.");
		}
	}
*/
	/**
	* Set the attribute of the object with binary content from the file dowloaded
	* @param objectId - The Id of the object to be accessed.
	* @param attribute - The attribute to be set
	* @param contentFile - The java.io.file object which content will be read and set
	*					   into the object specified by the Id
	* @exception PmpUnsupportedTypeException - The attribute specified does not support raw data type
	* @exception PmpInvalidAttributeException - The object does not contain the attribute specified
	* @exception IOException - File reading error.
	* @exception PmpInternalException - Internal error.
	*/
/*	public void setAttributeValueWithFile(int objectId, String attribute, File contentFile)
		throws FileTransferException, FileNotFoundException, IOException
	{

		OmsMember member = null;
		OmsAttribDef attDef = null;
		try
		{
			member = new OmsMember(this.sess, objectId);
		}
		catch(OmsException e)
		{
			throw new FileTransferException("Cannot instantiate member. " + e.toString());
		}

		try
		{
			attDef = new OmsAttribDef(this.sess, attribute);
		}
		catch(OmsException e)
		{
			throw new FileTransferException("Cannot retrieve attribute definition. " + e.toString());
		}

		int type = attDef.getType();

		//If the attribute type is raw, read the file and set it into the object itself
		if(type == OmsAttribDef.OMS_RAW)
		{
			final int contentFileSize = (int)contentFile.length();
			if (debug > 1)
			{
				System.out.println("Get save File: " + attribute);
				System.out.println("contentFile abs. path :" + contentFile.getAbsolutePath());
				System.out.println("File size is:" + contentFileSize);
			}
			FileInputStream contentInput = new FileInputStream(contentFile);
			byte contentBuf[] = new byte[contentFileSize];
			int readSize = contentInput.read(contentBuf);
			if (readSize != contentFileSize)
			{
				System.out.println("Caution!! content file size is :" + contentFileSize + " and readSize is :" + readSize);
			}
			try
			{
				member.setRaw(attribute, contentBuf);
				member.setAttValue();
			}
			catch(OmsException e)
			{
				throw new FileTransferException("Cannot save the content into object. " + e.toString());
			}

        }
		//else if the attribute is string, verify the sub-directory that belongs to the object
		//copy the file into that sub-directory and set the attribute to be the file name
		else if (type == OmsAttribDef.OMS_STRING)
		{
        	//First figure out the file name for this content file.  Additional operation is
        	//performed to ensure uniqueness of the file name.
        	//The file name will be <default path>/<object Id>/<attribute>-<originalfilename>
        	String outputFileName = saveFile(objectId, attribute, contentFile);

			//Set the attribute to be the file path.  We only storage the relative path because
			//in case admin move the storage to anyother place this attribute value will still
			//be valid.
			try
			{
				member.setStringAttrib(attribute, outputFileName, false);
				member.setAttValue();
			}
			catch(OmsException e)
			{
				throw new FileTransferException("Cannot save the content into object. " + e.toString());
			}

		}
		//else, throw an exception
		else
		{
			throw new FileTransferException("Attribute " + attribute + " is not of type Raw or String.");
		}
	}
*/
	// just save the uploaded file to the designated directory path
	// do not store attribute values into member object
	// return the outputFile name
	public attachment saveFile(int objectId, File contentFile)
		throws PmpException, FileTransferException, FileNotFoundException, IOException
	{
		return saveFile(objectId, contentFile, false);
	}
	
	public attachment saveFile(int objectId, File contentFile, boolean bVersioning)
	throws PmpException, FileTransferException, FileNotFoundException, IOException
	{
		return saveFile(objectId, null, contentFile, null, null, null, null, bVersioning);
	}

	public attachment saveFile(int objectId, String projIdS,
			File contentFile, String newFileName, String attType, String deptName,
			StringBuffer retFileNameBuf, boolean bVersioning)
		throws PmpException, FileTransferException, FileNotFoundException, IOException
	{
		// @ECC050207 Upload file size limit
		boolean bExceedFileSizeLimit = false;
		long fsize = contentFile.length();
		String msg = "";
		try {checkUploadFileSize(contentFile);}		// will throw exception if exceed limit
		catch (FileTransferException e) {bExceedFileSizeLimit = true; msg = e.toString();}

		File subDirectory;
		String relPath;
		String contentOriginalName = contentFile.getName();
		int idx = contentOriginalName.lastIndexOf('.');
		String ext = null;
		if (idx != -1) ext = contentOriginalName.substring(idx+1).toLowerCase();	// need this for attachment
		
		if (retFileNameBuf!=null && IMAGE_EXT.indexOf(ext) != -1)
		{
			// this is an image file, we will put the file under Tomcat directory to be shown on webpage
			newFileName = objectId + "." + ext;			// 12345.gif where 12345 is blog id
			subDirectory = new File(picFileStoragePath);
			newFileName = getVersionFileName(newFileName, subDirectory);
			String fullFileName = picFileStoragePath + "/" + newFileName;	// D:/Tomcat/..../file/memberPic/jsmith.gif

			if (debug > 1)
				l.info("Saving image file: " + fullFileName);

			// skrink the file if it exceeds IMG_FSIZE_LIMIT
			//Start the read/write operation
			readWriteFile(contentFile, fullFileName, (fsize>IMG_FSIZE_LIMIT), DEFAULT_PIC_WIDTH, DEFAULT_PIC_HEIGHT);
			if (retFileNameBuf != null)
				retFileNameBuf.append(picFileURL + "/" + newFileName);
			return null;
		}
		
		if (bExceedFileSizeLimit) throw new FileTransferException(msg);
		
		// @AGQ041906 save file with new filename
		if (newFileName!=null && newFileName.length()>0 && idx!=-1)
			contentOriginalName = newFileName + "." + ext;	// add original extension

		//Check to see if the object sub-directory is ready or not
		String subDirStr = storagePath + File.separator + objectId;
		subDirectory = new File(subDirStr);

		//If not exist, create it.
		if(!subDirectory.exists())
			subDirectory.mkdirs();

		// Use "/" instead of File.separator because java skip the window's File.separator
		relPath = "/" + objectId + "/" + contentOriginalName;
		String absoluteOutputFileName = storagePath + relPath;

		// @041505ECC
		PstAbstractObject linkAtt = null;
		if (bVersioning)
		{
			contentOriginalName = getVersionFileName(contentOriginalName, subDirectory);

			// use new version file name
			relPath = "/" + objectId + "/" + contentOriginalName;
			absoluteOutputFileName = storagePath + relPath;
			
			// check for linked files
			if (Util3.getFileVersion(contentOriginalName) > 1)
			{
				linkAtt = Util3.getOldestVersionFile(thisUser, objectId, contentOriginalName);
				if (linkAtt!=null && linkAtt.getAttribute("Link")[0]==null)
					linkAtt = null;
			}
		}
		if (debug > 1)
			l.info("Saving file: " + absoluteOutputFileName);

		//Start the read/write operation
		// ECC: the file is already on the local drive: I only need to rename the file
		File newFile = new File(absoluteOutputFileName);
		contentFile.renameTo(newFile);
		
		// create the attachment object
		attachment att = (attachment)attMgr.create(thisUser,
				String.valueOf(thisUser.getObjectId()),
				relPath,
				ext,
				projIdS,
				attType,
				deptName);
		if (linkAtt != null)
		{
			// copy linked info to the new attachment object
			att.setAttribute("Link", linkAtt.getAttribute("Link"));
			attMgr.commit(att);
		}
		return att;
	}

	public static String getVersionFileName(String contentOriginalName, File subDirectory)
	{
		// support versioning: never overwrite existing file
		int idx1=-1, idx2;
		if (debug > 1)
			System.out.println("File upload versioning is on");
		int version = 0;

		// create another version: e.g. abc(1).doc or abc(1)
		idx2 = contentOriginalName.lastIndexOf(')');
		if (idx2 < 0)
		{
			idx2 = contentOriginalName.lastIndexOf('.');
			if (idx2 < 0)
				idx2 = contentOriginalName.length();	// no extension
		}
		else
			idx1 = contentOriginalName.lastIndexOf('(');
		if (idx1 < 0)
		{
			// no version no. yet
			idx1 = idx2;			// either points to "." or end of string
		}
		else
		{
			// found "(" and ")": might already has version number
			idx1++;		// idx1 now pts to beginning of version num
			for (int i=idx1; i<idx2; i++)
			{
				if (!Character.isDigit(contentOriginalName.charAt(i)))
				{
					idx1=++idx2;	// not digit, take it as part of the filename
					break;			// pointing at "." or end of string
				}
			}
		}

		// need to find the highest number file, use that
		// version and increment by 1 as the new version number
		String [] ls;
		FilenameFilter filter = new MyFileFilter(
				contentOriginalName.substring(0,idx1),	// prefix
				contentOriginalName.substring(idx2));	// subfix
		ls = subDirectory.list(filter);
		int num = 0;
		int i1, i2;
		for (int i=0; ls!=null && i<ls.length; i++)
		{
			//if (debug > 1) System.out.println(i + "=" + ls[i]);
			i1 = ls[i].lastIndexOf('(')+1;
			i2 = ls[i].lastIndexOf(')');
			try {num = Integer.parseInt(ls[i].substring(i1, i2));}
			catch (Exception e) {continue;}
			if (num > version)
				version = num;
		}
		version++;
		if (debug > 1) System.out.println("version="+version);
		if (idx1 != idx2) {idx1--; idx2++;}		// exclude the ( and )
		contentOriginalName =
			contentOriginalName.substring(0,idx1)
			+ "(" + version + ")"
			+ contentOriginalName.substring(idx2);
		
		return contentOriginalName;
	}
	/**
	 * @ECC100507
	 * Save picture file for user object.  It will update the user object attribute
	 * PictureFile to reflect the relative URL of the picture file.
	 * 
	 * @param contentFile - the file object the user is uploading.
	 * @return urlFileName - the URL to display the user picture
	 */
	public String savePictureFile(File contentFile)
		throws FileTransferException, IOException, PmpException
	{
		return savePictureFile(contentFile, null);
	}
	public String savePictureFile(File contentFile, String idS)
		throws FileTransferException, IOException, PmpException
	{
		long fsize = contentFile.length();

		String contentOriginalName = contentFile.getName();
		int idx = contentOriginalName.lastIndexOf('.');
		String ext = "";
		if (idx != -1) ext = contentOriginalName.substring(idx+1).toLowerCase();	// only use lowercase ext
		
		String name;
		if (idS == null)
			name = String.valueOf(thisUser.getObjectId());
		else
			name = idS;
		String newFileName = name + "." + ext;		// 12345.gif where 12345 is user ID
		String fullFileName = picFileStoragePath + "/" + newFileName;	// D:/Tomcat/..../file/memberPic/jsmith.gif

		if (debug > 1)
			l.info("Saving picture file: " + newFileName + " for user [" + thisUser.getObjectName() + "]");

		//Start the read/write operation
		readWriteFile(contentFile, fullFileName, (fsize>ICON_FSIZE_LIMIT), 100, 100);
		return newFileName;
	}
	
	
	/**
	* Save the value of an attribute into the local file directory and return the URL of it
	* The file will be save with name equals to attribute name and extension equal to the
	* extension argument passed.  If the user did not pass in the extension then the file
	* will NOT have any extension.
	*
	* @param objectId - The Id of the object to be access
	* @param attribute - The attribute to be access
	*/
	public URL saveFileIntoLocalDirectory(int objectId, String attribute)
		throws FileTransferException, FileNotFoundException, IOException, MalformedURLException
	{
		OmsMember member = null;
		//OmsOrganization org = null;
		OmsAttribDef attDef = null;
		try
		{
			member = new OmsMember(this.sess, objectId);
			//org = member.getOrganization();
		}
		catch(OmsException e)
		{
			throw new FileTransferException("Cannot instantiate member. " + e.toString());
		}

		try
		{
			attDef = new OmsAttribDef(this.sess, attribute);
		}
		catch(OmsException e)
		{
			throw new FileTransferException("Cannot retrieve attribute definition. " + e.toString());
		}

		int type = attDef.getType();
		String filePath = "";
		File returnFile = null;

		//If the attribute is of type String, since retrive the file from file system
		//then convert to URL and send it to the client
		if (type == OmsAttribDef.OMS_STRING)
		{
			if (debug > 1)
			{
				System.out.println("Get URL File: " + attribute);
			}
			try
			{
				//Get the attribute from the object
				filePath = member.getStringValue(attribute);
			}
			catch(OmsException e)
			{
				throw new FileTransferException("Cannot retrieve value stored in attribute " + attribute + " of object with Id = :" + objectId);
			}
			//Append the name with the storage path from system
			String absolutePath = storagePath + File.separator + filePath;
			returnFile = new File(absolutePath);
			if (debug > 1)
				l.info("The absolutePath1 is:" + absolutePath);
			//If it is string then the file should already exist in the file system.
			if (!returnFile.exists())
				throw new FileTransferException("File " + absolutePath + " does not exists!");
//			else
			if (debug > 1)
				System.out.println(returnFile.getAbsolutePath()+" already exist.  Good.");
		}
		//Otherwise, retrieve the raw content from the object, save it to the
		//sub-directory that belongs to the object
		else if(type == OmsAttribDef.OMS_RAW)
		{
			if (debug >1 )
				System.out.println("Get URL File: " + attribute);
			try
			{

				String newContentFileName = attribute;
				String outputFileName = objectId + File.separator + newContentFileName;
				String absolutePath = storagePath + File.separator + outputFileName;
				returnFile = new File(absolutePath);

				byte [] contentBuff = member.getRaw(attribute);
				if (debug > 1)
					System.out.println("The raw value size is :" + contentBuff.length);

				//If the file exist, delete it.  Then create a new empty file..
				if (returnFile.exists())
					returnFile.delete();

				if (!returnFile.exists())
					returnFile.createNewFile();
				else
					throw new FileTransferException("Cannot delete existing file :" + returnFile.getAbsolutePath());

				FileOutputStream fos = new FileOutputStream(returnFile);
				fos.write(contentBuff);
				fos.flush();
				fos.close();
				if (debug > 1)
					System.out.println("Finish write file "+ returnFile.getAbsolutePath() +" into local directory.");
			}
			catch(OmsException e)
			{
				throw new FileTransferException("Cannot get raw value from attribute " + attribute + " of object (ID) " + objectId);
			}

		}
		//Throw exception because of attribute type mismatch
		else
		{
			throw new FileTransferException("Attribute " + attribute + " is not of type Raw or String.");
		}

		return returnFile.toURI().toURL();

	}

	public byte[] retrieveFileFromObject(String objectName, OmsOrganization org, String attribute)
		throws FileTransferException, FileNotFoundException, IOException
	{
		OmsMember member = null;
		OmsAttribDef attDef = null;
		try
		{
			member = new OmsMember(this.sess, org, objectName);
		}
		catch(OmsException e)
		{
			throw new FileTransferException("Cannot instantiate member. " + e.toString());
		}
		try
		{
			attDef = new OmsAttribDef(this.sess, attribute);
		}
		catch(OmsException e)
		{
			throw new FileTransferException("Cannot retrieve attribute definition. " + e.toString());
		}

		int type = attDef.getType();
		//If the attribute type is raw, simply call the object.get() methid
		if (type == OmsAttribDef.OMS_RAW)
		{
			if (debug > 1)
				System.out.println("Retrieve File: " + attribute);
			try
			{
				return member.getRaw(attribute);
			}
			catch(OmsException e)
			{
				throw new FileTransferException("Cannot retrieve attribute value for " + attribute +". " + e.toString());
			}
		}
		//else, get the value from the object, go into the sub-directory and
		//return the byte[] back.
		else if (type == OmsAttribDef.OMS_STRING)
		{
			if (debug > 1)
				System.out.println("Retrieve File: " + attribute);
			String filePath = "";
			try
			{
				//Get the attribute from the object.  If nothing stored then
				//return null
				filePath = member.getStringValue(attribute);
				if (filePath == null)
					return null;
			}
			catch(OmsException e)
			{
				throw new FileTransferException("Cannot retrieve value stored in attribute " + attribute + " of object with name = :" + objectName);
			}

			//Append the name with the storage path from system
			String absolutePath = storagePath;
			char c = filePath.charAt(0);
			if (c!='/' && c!='\\')
				absolutePath += File.separator;
			absolutePath += filePath;
			File returnFile = new File(absolutePath);

			if (debug > 1)
				l.info("The absolutePath2 is:" + absolutePath);

			//If it is string then the file should already exist in the file system.
			if (!returnFile.exists())
				throw new FileTransferException("File " + absolutePath + " does not exists!");
			else
			{
				final int buffNum = (int)returnFile.length();
				if (debug > 1)
					System.out.println("length of the file :" + buffNum);
				byte [] returnArray = new byte[buffNum];
				FileInputStream fis = new FileInputStream(returnFile);
				int len = fis.read(returnArray);
				fis.close();
				if (debug > 1)
					System.out.println("len is :" + len);
				if (len != buffNum)
					throw new FileTransferException("Cannot read up to the size of the file.");
				else
					return returnArray;
			}
		}
		else
		{
			throw new FileTransferException("Attribute " + attribute + " is not of type Raw or String.");
		}
	}


	/**
	* Retrieve file content from the object
	*/
	public byte[] retrieveFileFromObject(int objectId, String attribute)
		throws FileTransferException, FileNotFoundException, IOException
	{
		OmsMember member = null;
		//OmsOrganization org = null;
		OmsAttribDef attDef = null;
		try
		{
			member = new OmsMember(this.sess, objectId);
			//org = member.getOrganization();
		}
		catch(OmsException e)
		{
			throw new FileTransferException("Cannot instantiate member. " + e.toString());
		}
		try
		{
			attDef = new OmsAttribDef(this.sess, attribute);
		}
		catch(OmsException e)
		{
			throw new FileTransferException("Cannot retrieve attribute definition. " + e.toString());
		}

		int type = attDef.getType();
		//If the attribute type is raw, simply call the object.get() methid
		if (type == OmsAttribDef.OMS_RAW)
		{
			if (debug > 1)
				System.out.println("Retrieve File: " + attribute);
			try
			{
				return member.getRaw(attribute);
			}
			catch(OmsException e)
			{
				throw new FileTransferException("Cannot retrieve attribute value for " + attribute +". " + e.toString());
			}
		}
		//else, get the value from the object, go into the sub-directory and
		//return the byte[] back.
		else if (type == OmsAttribDef.OMS_STRING)
		{
			System.out.println("Retrieve File: " + attribute);
			String filePath = "";
			try
			{
				//Get the attribute from the object.  If nothing stored then
				//return null
				filePath = member.getStringValue(attribute);
				if (filePath == null)
					return null;
			}
			catch(OmsException e)
			{
				throw new FileTransferException("Cannot retrieve value stored in attribute " + attribute + " of object with Id = :" + objectId);
			}

			//Append the name with the storage path from system
			String absolutePath = storagePath + File.separator + filePath;
			File returnFile = new File(absolutePath);
			if (debug > 1)
				l.info("The absolutePath3 is:" + absolutePath);

			//If it is string then the file should already exist in the file system.
			if (!returnFile.exists())
				throw new FileTransferException("File " + absolutePath + " does not exists!");
			else
			{
				final int buffNum = (int)returnFile.length();
				if (debug > 1)
					System.out.println("length of the file :" + buffNum);
				byte [] returnArray = new byte[buffNum];
				FileInputStream fis = new FileInputStream(returnFile);
				int len = fis.read(returnArray);
				fis.close();
				if (debug > 1)
					System.out.println("len is :" + len);
				if (len != buffNum)
					throw new FileTransferException("Cannot read up to the size of the file.");
				else
					return returnArray;
			}
		}
		else
		{
			throw new FileTransferException("Attribute " + attribute + " is not of type Raw or String.");
		}
	}


	// simply go to the storage directory and get the file
	public String placeFileOnServer(String fileName)
		throws FileTransferException, FileNotFoundException, IOException
	{
		String absolutePath = getAbsolutePath(fileName);
		return placeFile(absolutePath);
	}

// @AGQ062706
	
	/**
	 * Determines if the current fileName is an absolute path.
	 * If it is returns the absolute path. If not constructs
	 * the repository path
	 * @param fileName retreives the fileName from db
	 * @return absolutPath of the fileName
	 */
	private String getAbsolutePath(String fileName) {
		if (Util.isAbsolutePath(fileName))
			return fileName;
		else
		{
			char c = fileName.charAt(0);
			if (c!='/' && c!='\\')
				return storagePath + File.separator + fileName;
			else
				return storagePath + fileName;
		}
	}

	/**
	 * Retrieve file content and place it on a Tomcat server directory, return URL
	 * @param objectId
	 * @param attribute name, for Attachment organization it is "Location"
	 * @return return URL of the file for caller to access through HTTP
	 * @throws FileTransferException
	 * @throws FileNotFoundException
	 * @throws IOException
	 */
	public String placeFileOnServer(int objectId, String attribute)
			throws FileTransferException, FileNotFoundException, IOException
	{
		OmsMember member = null;
		//OmsOrganization org = null;
		OmsAttribDef attDef = null;
		try
		{
			member = new OmsMember(this.sess, objectId);
			//org = member.getOrganization();
		}
		catch(OmsException e)
		{
			throw new FileTransferException("Cannot instantiate member. " + e.toString());
		}
		try
		{
			attDef = new OmsAttribDef(this.sess, attribute);
		}
		catch(OmsException e)
		{
			throw new FileTransferException("Cannot retrieve attribute definition. " + e.toString());
		}

		int type = attDef.getType();
		if (type == OmsAttribDef.OMS_STRING)
		{	// the attribute should contain the relative filePath, such as that of Attachment
			String filePath = "";
			try
			{
				//Get the attribute from the object.  If nothing stored then
				//return null
				filePath = member.getStringValue(attribute);
				if (filePath == null)
					return null;
			}
			catch(OmsException e)
			{
				throw new FileTransferException("Cannot retrieve value stored in attribute " + attribute + " of object with Id = :" + objectId);
			}

			//Append the name with the storage path from system
			String absolutePath = storagePath + File.separator + filePath;
			return placeFile(absolutePath);
		}
		else
		{
			throw new FileTransferException("Attribute " + attribute + " is not of type Raw or String.");
		}
	}

	public String placeArcvFileOnServer(String fileName)
		throws FileTransferException, FileNotFoundException, IOException
	{
		// fileName is townId/filename.htm
		String absolutePath = arcvFilePath + File.separator + fileName;
		return placeFile(absolutePath);
	}

	/**
	 * actually extract the path from the OMM file folder location and put it on the URL
	 * @param absolutePath
	 * @return the URL of the file placed
	 * @throws FileTransferException
	 * @throws FileNotFoundException
	 * @throws IOException
	 */
	private String placeFile(String absolutePath)
		throws FileTransferException, FileNotFoundException, IOException
	{
		File returnFile = new File(absolutePath);
		String nameOnly = returnFile.getName().replace("Attachment-", "");	// @AGQ061606
		//String nameOnly = returnFile.getName().substring(11);		// @041505ECC remove "Attachment-"

		if (debug > 1)
			l.info("The absolutePath4 is:" + absolutePath);

		//If it is string then the file should already exist in the file system.
		if (!returnFile.exists())
			throw new FileTransferException("File " + absolutePath + " does not exists!");
		else
		{
			String returnFileName = "/" + nameOnly;
			String absFileName = this.showFilePath + returnFileName;

			File newFile = new File(absFileName);
			
			// @041505ECC
			boolean bCreate = true;
			if (newFile.exists())
			{
				long now = new Date().getTime();
				long lastT = newFile.lastModified();
				if (now - lastT > 15000)
				{
					// the temp file was more than 15 sec old, delete and recreate
					newFile.delete();
				}
				else
				{
					bCreate = false;
					newFile.setLastModified(now);
					if (debug > 1)
						System.out.println("Use existing show file: " + newFile.getAbsolutePath());
				}
			}
			if (bCreate)
			{
				// need to create/re-create the show file
				final int buffNum = (int)returnFile.length();
				if (debug > 1)
					System.out.println("Length of the file = " + buffNum);
// @AGQ033106
				byte [] contentBuf = new byte[4096];	// it was 256
				FileInputStream fis = new FileInputStream(returnFile);
				
				newFile.createNewFile();
				FileOutputStream fos = new FileOutputStream(newFile);
				
				int count = 0;
				int len = 0; // Check total length read
				while((count = fis.read(contentBuf)) != -1)
				{
					fos.write(contentBuf, 0, count);
					fos.flush();
					len += count;
				}
				
				fis.close();
				fos.close();
				
				if (debug > 1)
					System.out.println("Read len = " + len);
				if (len != buffNum)
					throw new FileTransferException("Cannot read up to the size of the file.");
				
				if (debug > 1)
					System.out.println("Created new show file: " + newFile.getAbsolutePath());
			}
			
			// http://183.238.5.149/PRM/file\\CPM-2014年7月报表(1).xlsx
			returnFileName = this.URLname + returnFileName;
			returnFileName = returnFileName.replaceAll("\\\\", "/");
			return (returnFileName);
		}
	}

	public void removeFileFromObject(String objectName, OmsOrganization org, String attribute)
		throws FileTransferException, FileNotFoundException, IOException
	{
		OmsMember member = null;
		OmsAttribDef attDef = null;
		try
		{
			member = new OmsMember(this.sess, org, objectName);
		}
		catch(OmsException e)
		{
			throw new FileTransferException("Cannot instantiate member. " + e.toString());
		}
		try
		{
			attDef = new OmsAttribDef(this.sess, attribute);
		}
		catch(OmsException e)
		{
			throw new FileTransferException("Cannot retrieve attribute definition. " + e.toString());
		}

		int type = attDef.getType();

		//If the attribute is raw, simply call the object.set() with empty byte array
		if (type == OmsAttribDef.OMS_RAW)
		{
			if (debug > 1)
				System.out.println("Remove file :" + attribute);
			byte [] tempArray = new byte[0];
			try
			{
				member.setRaw(attribute, tempArray);
				member.setAttValue();
			}
			catch(OmsException e)
			{
				throw new FileTransferException("Cannot set raw attribute "+ attribute +". " + e.toString());
			}
		}
		//else, get the value from the object, go into the sub-directory and
		//delete the file.
		else if (type == OmsAttribDef.OMS_STRING)
		{
			if (debug > 1)
				l.info("Remove File: " + attribute);
			String filePath = "";
			try
			{
				//Get the attribute from the object
				filePath = member.getStringValue(attribute);
			}
			catch(OmsException e)
			{
				throw new FileTransferException("Cannot retrieve value stored in attribute " + attribute + " of object with name = :" + objectName);
			}

			//Append the name with the storage path from system
			String absolutePath = storagePath + File.separator + filePath;
			File returnFile = new File(absolutePath);

			//If it doesn't exists, throw an exception
			if (!returnFile.exists())
				throw new FileTransferException("File " + absolutePath + " does not exists!");
			//Otherwise, delete the file and clean up the object's attribute
			else
			{
				returnFile.delete();
				try
				{
					member.setStringAttrib(attribute, "", false);
					member.setAttValue();
				}
				catch(OmsException e)
				{
					throw new FileTransferException("Cannot set string attribute"+ attribute +". " + attribute + " of object with name = :" + objectName);
				}
			}
		}
		else
		{
			throw new FileTransferException("Attribute " + attribute + " is not of type Raw or String.");
		}
	}


	public void removeFileFromObject(int objectId, String attribute)
		throws FileTransferException, FileNotFoundException, IOException
	{
		OmsMember member = null;
		//OmsOrganization org = null;
		OmsAttribDef attDef = null;
		try
		{
			member = new OmsMember(this.sess, objectId);
			//org = member.getOrganization();
		}
		catch(OmsException e)
		{
			throw new FileTransferException("Cannot instantiate member. " + e.toString());
		}
		try
		{
			attDef = new OmsAttribDef(this.sess, attribute);
		}
		catch(OmsException e)
		{
			throw new FileTransferException("Cannot retrieve attribute definition. " + e.toString());
		}

		int type = attDef.getType();

		//If the attribute is raw, simply call the object.set() with empty byte array
		if (type == OmsAttribDef.OMS_RAW)
		{
			if (debug > 1)
				l.info("Remove file :" + attribute);
			byte [] tempArray = new byte[0];
			try
			{
				member.setRaw(attribute, tempArray);
				member.setAttValue();
			}
			catch(OmsException e)
			{
				throw new FileTransferException("Cannot set raw attribute "+ attribute +". " + e.toString());
			}
		}
		//else, get the value from the object, go into the sub-directory and
		//delete the file.
		else if (type == OmsAttribDef.OMS_STRING)
		{
			if (debug > 1)
				System.out.println("Remove File: " + attribute);

			String filePath = "";
			try
			{
				//Get the attribute from the object
				filePath = member.getStringValue(attribute);
			}
			catch(OmsException e)
			{
				throw new FileTransferException("Cannot retrieve value stored in attribute " + attribute + " of object with Id = :" + objectId);
			}

			//Append the name with the storage path from system
			String absolutePath = storagePath + File.separator + filePath;
			File returnFile = new File(absolutePath);

			//If it doesn't exists, throw an exception
			if (!returnFile.exists())
				throw new FileTransferException("File " + absolutePath + " does not exists!");
			//Otherwise, delete the file and clean up the object's attribute
			else
			{
				returnFile.delete();
				try
				{
					member.setStringAttrib(attribute, "", false);
					member.setAttValue();
				}
				catch(OmsException e)
				{
					throw new FileTransferException("Cannot set string attribute"+ attribute +". " + attribute + " of object with Id = :" + objectId);
				}
			}
		}
		else
		{
			throw new FileTransferException("Attribute " + attribute + " is not of type Raw or String.");
		}
	}

	private long checkUploadFileSize(File contentFile)
	throws FileTransferException
	{
		long fileSize = contentFile.length();
		if (uploadSizeLimit>0 && fileSize>uploadSizeLimit)
		{
			// file size exceed upload file size
			int i = (int)(uploadSizeLimit / ONE_MEG);
			String msg;
			if (i < 0) msg = String.valueOf(uploadSizeLimit) + " Bytes";
			else msg = String.valueOf(i) + " MB";
			l.info("FileTransfer.checkUploadFileSize(): attempt to upload file [" + contentFile.getName() + "] size (" + fileSize + ").");
			throw new FileTransferException("Cannot upload file [" + contentFile.getName() + "] that is larger than " + msg + ".");
		}
		return fileSize;
	}

	private void readWriteFile(File contentFile, String newFileName, boolean bNeedShrink, int thumbWidth, int thumbHeight)
		throws IOException
	{		
		if (bNeedShrink)
		{
			Image image = Toolkit.getDefaultToolkit().getImage(contentFile.getAbsolutePath());
		    MediaTracker mediaTracker = new MediaTracker(new Container());
		    mediaTracker.addImage(image, 0);
		    try {mediaTracker.waitForID(0);}
		    catch (InterruptedException e) {}
		    
		    // determine thumbnail size from WIDTH and HEIGHT
		    double thumbRatio = (double)thumbWidth / (double)thumbHeight;
		    int imageWidth = image.getWidth(null);
		    int imageHeight = image.getHeight(null);
		    double imageRatio = (double)imageWidth / (double)imageHeight;
		    if (thumbRatio < imageRatio)
		      thumbHeight = (int)(thumbWidth / imageRatio);
		    else
		      thumbWidth = (int)(thumbHeight * imageRatio);

		    // draw original image to thumbnail image object and
		    // scale it to the new size on-the-fly
		    BufferedImage thumbImage = new BufferedImage(thumbWidth,
		      thumbHeight, BufferedImage.TYPE_INT_RGB);
		    Graphics2D graphics2D = thumbImage.createGraphics();
		    graphics2D.setRenderingHint(RenderingHints.KEY_INTERPOLATION,
		      RenderingHints.VALUE_INTERPOLATION_BILINEAR);
		    graphics2D.drawImage(image, 0, 0, thumbWidth, thumbHeight, null);
		    // save thumbnail image to OUTFILE
		    BufferedOutputStream out = new BufferedOutputStream(new
		      FileOutputStream(newFileName));
		    JPEGImageEncoder encoder = JPEGCodec.createJPEGEncoder(out);
		    JPEGEncodeParam param = encoder.
		      getDefaultJPEGEncodeParam(thumbImage);
		    int quality = DEFAULT_PIC_QUALITY;
		    param.setQuality((float)quality / 100.0f, false);
		    encoder.setJPEGEncodeParam(param);
		    encoder.encode(thumbImage);
		    out.close();
		}
		else
		{
			// regular file or no shrinking needed
			FileOutputStream localFile = new FileOutputStream(newFileName);
			FileInputStream fis = new FileInputStream(contentFile);
			final int bufferNum = 8192;
			byte buf[] = new byte[bufferNum];
			int len = 0;
		
			while (len != -1)
			{
				len = fis.read(buf, 0, bufferNum);
				if (len == -1)
					break;
		
				localFile.write(buf, 0, len);
			}
		
			fis.close();
			localFile.flush();
			localFile.close();
		}
	
		// delete the uploaded copy
		contentFile.delete();
	}

}
