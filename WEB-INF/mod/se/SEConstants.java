//
//	Copyright (c) 2006, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: SEConstants.java
//	Author: AGQ
//	Date:	06/16/06
//	Description: Constants.
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
package mod.se;

public interface SEConstants {
	public static final String ID = "id";
	public static final String CONTENTS = "contents";
	public static final String FILENAME = "filename";
	public static final String PATH = "path";

	public static final String SE_INDEX_PATH = "SE_INDEX_PATH";
	public static final String FILE_UPLOAD_PATH = "FILE_UPLOAD_PATH";
	public static final String PST = "pst";

	// extensions
	public static final String PDF = ".pdf";
	public static final String DOC = ".doc";
	public static final String PPT = ".ppt";
	public static final String XLS = ".xls";
	public static final String HTML = ".html";
	public static final String HTM = ".htm";
	public static final String ZIP = ".zip";
	public static final String MSG = ".msg";
	public static final String TXT = ".txt";
	public static final String MPP = ".mpp";

	// Ignore file types
	public static final String DLL = ".dll";
	public static final String EXE = ".exe";
	public static final String JPG = ".jpg";
	public static final String GIF = ".gif";
	public static final String MOV = ".mov";
	public static final String JPEG = ".jpeg";
	public static final String AVI = ".avi";
	public static final String BMP = ".bmp";
	public static final String MID = ".mid";
	public static final String MIDI = ".midi";
	public static final String MPG = ".mpg";
	public static final String PNG = ".png";
	public static final String PSD = ".psd";
	public static final String QT = ".qt";
	public static final String QTI = ".qti";
	public static final String RM = ".rm";
	public static final String SWF = ".swf";
	public static final String TIF = ".tif";
	public static final String TIFF = ".tiff";
	public static final String MP3 = ".mp3";
	public static final String [] IGNOREEXT = {DLL, EXE, JPG, GIF, MOV, JPEG,
		AVI, BMP, MID, MIDI, MPG, PNG, PSD, QT, QTI, RM, SWF, TIF, TIFF, MP3};
}
