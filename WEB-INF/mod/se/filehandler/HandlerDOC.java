package mod.se.filehandler;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;

import org.textmining.text.extraction.WordExtractor;

public class HandlerDOC extends Handler {
	public HandlerDOC(String fileLocation) {
		super(fileLocation);
	}
	
	public boolean extractInfo() {
		FileInputStream in = null;
		try {
			File file = new File(getFileLocation());
			if (file.exists() && file.canRead() && !file.isDirectory()) {
				String contents;
		    	WordExtractor extractor = new WordExtractor();
		    	in = new FileInputStream(file);
		    	contents = extractor.extractText(in);
		    	setContents(contents);
		    	return true;
			}
			else 
				return false;
		} catch (IOException e) {
			l.error(e);
			return super.extractInfo();
		} catch (Exception e) {
			l.error(getFileLocation() + " " + e);
			return super.extractInfo();
		}
		finally {
			try {
				if (in != null)
					in.close();
			}
			catch (IOException e) {}
		}
	}
}
