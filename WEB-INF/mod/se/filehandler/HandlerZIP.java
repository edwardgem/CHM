package mod.se.filehandler;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Enumeration;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

public class HandlerZIP extends Handler {
	private String directory;
	
	public String getDirectory() {
		return directory;
	}

	public void setDirectory(String directory) {
		this.directory = directory;
	}

	public HandlerZIP(String fileLocation) {
		super(fileLocation);
		directory = null;
	}
	
	private boolean makeDirectory() {
		if (directory != null) {
			File newDir = (new File(directory));
			
			if (!newDir.exists()) {
				newDir.mkdirs();
				return true;
			}
			else {
				directory += "1";
				return makeDirectory();
			}
		}
		return false;
	}
	
	public boolean extractInfo() {	
		Enumeration entries;
	    ZipFile zipFile;
		try { 
			File file = new File(getFileLocation());
			if (file.exists() && file.canRead() && !file.isDirectory()) {	
				// Extract Files into directory
				
				String fileLocation = getFileLocation();
				int forwardIdx1 = fileLocation.lastIndexOf("/");
		    	int backwardIdx1 = fileLocation.lastIndexOf("\\");
		    	int pathIdx1 = (forwardIdx1>backwardIdx1)?forwardIdx1:backwardIdx1;
		    	
		    	String filename = (pathIdx1 != -1 && fileLocation.length() > pathIdx1)?fileLocation.substring(pathIdx1+1):"";
				
		    	if (filename.equalsIgnoreCase("soft_mtx_data.zip"))
		    		throw new IOException();
		    	
				int extensionIdx = getFileLocation().lastIndexOf(".");
				
				if (extensionIdx > 0) {
					directory = getFileLocation().substring(0, extensionIdx);
					makeDirectory();
			        zipFile = new ZipFile(file);
			        entries = zipFile.entries();

			        while(entries.hasMoreElements()) {
			          ZipEntry entry = (ZipEntry)entries.nextElement();
			          String entryName = directory + '/' + entry.getName();
			          if(entry.isDirectory()) {
			            (new File(entryName)).mkdirs();
			            continue;
			          }
			          else {
						int forwardIdx = entryName.lastIndexOf("/");
						int backwardIdx = entryName.lastIndexOf("\\");
						int pathIdx = (forwardIdx>backwardIdx)?forwardIdx:backwardIdx;
						String path = (pathIdx != -1)?entryName.substring(0, pathIdx):"";
						File dirName = new File(path);
						if (!dirName.exists())
							dirName.mkdirs();
			          }

			          copyInputStream(zipFile.getInputStream(entry),
			             new BufferedOutputStream(new FileOutputStream(entryName)));
			        }

			        zipFile.close();
			        return true;
				}
			}
			return false;
		} catch (IOException e) {
			l.error(e);
			return super.extractInfo();
		} catch (Exception e) {
			l.error(getFileLocation() + " " + e);
			return super.extractInfo();
		}
	}	
	
	  public static final void copyInputStream(InputStream in, OutputStream out)
	  throws IOException
	  {
	    byte[] buffer = new byte[8192];
	    int len;

	    while((len = in.read(buffer)) >= 0) {
	      out.write(buffer, 0, len);
	      out.flush();
	    }

	    in.close();
	    out.close();
	  }
}
