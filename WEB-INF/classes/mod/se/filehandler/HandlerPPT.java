package mod.se.filehandler;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;

import org.apache.poi.hslf.extractor.PowerPointExtractor;
import org.apache.poi.poifs.filesystem.POIFSFileSystem;

public class HandlerPPT extends Handler {
	public HandlerPPT(String fileLocation) {
		super(fileLocation);
	}
	
	public boolean extractInfo() {
		FileInputStream in = null;
		try {
			File file = new File(getFileLocation());
			if (file.exists() && file.canRead() && !file.isDirectory()) {
				in = new FileInputStream(file);
				POIFSFileSystem fs = new POIFSFileSystem(in);
		    	PowerPointExtractor p = new PowerPointExtractor(fs);
		    	String contents = p.getText(true, true);
		    	setContents(contents);
		    	return true;
			}
			else
				return false;
		} catch (IOException e) {
			l.error(e);
			return super.extractInfo();
		} catch (Exception e) {
			l.error(e);
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
