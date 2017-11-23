//
//  Copyright (c) 2010, EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   UtilIO.java
//  Author:
//  Date:   10/17/2010
//  Description:
//
/////////////////////////////////////////////////////////////////////
//
// UtilIO.java : implementation of the UtilIO class for PRM
//
package util;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;

public class UtilIO {
	
	/**
	 * 
	 * @param filePath
	 * @return
	 * @throws IOException
	 */
	public static BufferedReader getFileReader(String filePath)
		throws IOException
	{
		File inFile = new File(filePath);
		BufferedReader bufReader = new BufferedReader(new FileReader(inFile));
		return bufReader;
	}
}
