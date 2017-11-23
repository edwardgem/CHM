package mod.se.filehandler;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;

import org.apache.log4j.Logger;

import util.PrmLog;

public class Handler {
	static Logger l = PrmLog.getLog();
	
	private String fileLocation;
	private String contents;
	private String id;
	private String ext;
	
	public Handler() {
		fileLocation = null;
		contents = null;
		id = null;
		ext = null;
	}
	
	public Handler(String fileLocation) {
		this();
		
		setFileLocation(fileLocation);
		int extensionIdx = fileLocation.lastIndexOf(".");
		if (extensionIdx > 0)
			setExt(fileLocation.substring(extensionIdx).toLowerCase());		
	}

	/**
	 * Opens the document type and extracts all the information 
	 * into the attributes. Extended classes will override this 
	 * method to extract their own specific contents
	 * @param fileLocation
	 * @return
	 */
	public boolean extractInfo() {
		BufferedReader in = null;
		try {
			File file = new File(fileLocation);
			if (file.exists() && file.canRead() && !file.isDirectory()) {
				StringBuffer sb = new StringBuffer(4096);
				in = new BufferedReader(new FileReader(file));
		    	String str;
		    	while ((str = in.readLine()) != null) {
		    		sb.append(str);
		    	}
		    	in.close();
		    	
		    	setContents(sb.toString());
		    	return true;
			}
			else {
				l.error("File Not Found: " + fileLocation);
				return false;
			}
		} catch (IOException e) {
			l.error(e);
			e.printStackTrace();
		} catch (OutOfMemoryError ee) {
			l.error("Handler.extractInfo() got OutOfMemory Exception");
			l.error(ee);
			ee.printStackTrace();
		}
		finally {
			try {
				if (in != null)
					in.close();
			}
			catch (IOException e) {}
		}
		return false;
	}

	public String getContents() {
		return contents;
	}

	public void setContents(String contents) {
		// <= 32 should become a space
		// 33 - 127 are okay
		// 128 and up are foreign language
		int length = contents.length();
		StringBuffer filtered = new StringBuffer(length);
		boolean prevSpace = true;
		for (int i=0; i<length; i++) {
			char character = contents.charAt(i);
			if (character < 33 || character >= 128) {
				if (!prevSpace) {
					filtered.append(' ');
					prevSpace = true;
				}
			}
			else { 
				filtered.append(character);
				prevSpace = false;
			}
		}
		this.contents = filtered.toString();
	}

	public String getId() {
		return id;
	}

	public void setId(String id) {
		this.id = id;
	}

	public String getFileLocation() {
		return fileLocation;
	}

	public void setFileLocation(String path) {
		this.fileLocation = path;
	}

	public String getExt() {
		return ext;
	}

	public void setExt(String ext) {
		this.ext = ext;
	}
}
