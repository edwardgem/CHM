package mod.se.filehandler;

import java.io.File;
import java.io.IOException;
import java.io.StringWriter;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;

public class HandlerPDF extends Handler {
	public HandlerPDF(String fileLocation) {
		super(fileLocation);
	}
	
	public boolean extractInfo() {

        PDDocument pdfDocument = null;
        try {
System.out.println("++++ HandlerPDF.extractInfo(): " + getFileLocation());
    		File file = new File(getFileLocation());
    		
    		if (file.exists() && file.canRead() && !file.isDirectory()) {
    			
	            pdfDocument = PDDocument.load( new File(getFileLocation()) );
	
	            if( pdfDocument.isEncrypted() ) {
	                //Just try using the default password and move on
	                //pdfDocument.decrypt( "" );	// ECC: load with password
	            	pdfDocument.close();
	            	pdfDocument = PDDocument.load(new File(getFileLocation()), "");
	            }
	
	            //create a writer where to append the text content.
	            StringWriter writer = new StringWriter();
	            PDFTextStripper stripper = new PDFTextStripper();
	            stripper.writeText(pdfDocument, writer);
	
	            String contents = writer.getBuffer().toString();
	            System.out.println("Index PDF len = " + contents.length());
	            setContents(contents);
	            return true;
    		}
    		else {
    			return false;
    		}
        } catch (IOException e) {
        	l.error(e);
        	return super.extractInfo();
        } catch (Exception e) {
        	l.error(e);
        	return super.extractInfo();
        }
        finally {
        	try {
	            if( pdfDocument != null ) {
	                pdfDocument.close();
	            }
        	} catch (IOException e) {
        		l.error(e);
        		return super.extractInfo();
        	}
        }
	}
}