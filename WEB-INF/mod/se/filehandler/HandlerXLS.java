package mod.se.filehandler;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.Iterator;

import org.apache.poi.hssf.usermodel.HSSFCell;
import org.apache.poi.hssf.usermodel.HSSFRow;
import org.apache.poi.hssf.usermodel.HSSFSheet;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.apache.poi.poifs.filesystem.POIFSFileSystem;

public class HandlerXLS extends Handler {
	public HandlerXLS(String fileLocation) {
		super(fileLocation);
	}
	
	public boolean extractInfo() {	
		FileInputStream in = null;
		try { 
			File file = new File(getFileLocation());
			if (file.exists() && file.canRead() && !file.isDirectory()) {	
				StringBuffer sb = new StringBuffer();
				in = new FileInputStream(file);
				POIFSFileSystem fs = new POIFSFileSystem(in);
		    	HSSFWorkbook w = new HSSFWorkbook(fs);
		    	for (int sheet = 0; sheet < w.getNumberOfSheets(); sheet++) {
		    		HSSFSheet j = w.getSheetAt(sheet);
		    		String sheetName  = w.getSheetName(sheet).trim();
		    		if (sheetName.length() > 0) {
		    			sb.append(sheetName);
		    			sb.append(" ");
		    		}
		    		Iterator it = j.rowIterator();
		    		while(it.hasNext()) {
		    			HSSFRow r = (HSSFRow)it.next();
		    			Iterator itc = r.cellIterator();
		    			while(itc.hasNext()) {
		    				HSSFCell c = (HSSFCell)itc.next();
		    				String cellValue = c.toString().trim();
		    				if (cellValue.length() > 0) {
		    					sb.append(cellValue);
		    					sb.append(" ");
		    				}
		    			}
		    		}
		    	}
		    	setContents(sb.toString());
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