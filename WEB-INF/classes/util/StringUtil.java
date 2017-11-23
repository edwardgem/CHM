//
//  Copyright (c) 2010, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   StringUtil.java
//  Author: ECC
//  Date:   11.12.2010
//  Description:
//		Implementation of StringUtil class for internationalization.
//  Modification:
//
/////////////////////////////////////////////////////////////////////
//
// StringUtil.java : implementation of the StringUtil class
//
package util;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.util.HashMap;
import java.util.Iterator;

import oct.codegen.result;
import oct.codegen.userinfo;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;

import org.apache.log4j.Logger;
import org.apache.poi.hssf.usermodel.HSSFCell;
import org.apache.poi.hssf.usermodel.HSSFRow;
import org.apache.poi.hssf.usermodel.HSSFSheet;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;

public class StringUtil
{
	public static String DEFAULT_LOCALE	= userinfo.DEFAULT_LOCALE;
	
	private static final String RESOURCE_FILE_PATH = Prm.getResourcePath();
	
	public static int TYPE_LABEL		= 1;
	public static int TYPE_MESSAGE		= 2;
	
	private static String LABEL_FILENAME	= "label.xls";	// label.csv
	private static String MESSAGE_FILENAME	= "message.csv";
	
	// hash for labels
	private static HashMap<String,String> _labelHash;
	
	// hash for messages
	private static HashMap<String,String> _messageHash;

	static Logger l = PrmLog.getLog();
	
	/**
	 * 
	 * @param stringType either TYPE_LABEL or TYPE_MESSAGE
	 * @param locale can be null
	 * @param stringID
	 * @return
	 */
	public static String getLocalString (
			int stringType,
			String locale,
			String stringID,
			String ... vars
			)
	{
		HashMap<String,String> hash;
		if (stringType == TYPE_LABEL) {
			hash = _labelHash;
		}
		else {
			hash = _messageHash;
		}
		
		// initialize hash the first time it is used
		if (hash == null) {
			hash = fillStringHash(stringType, DEFAULT_LOCALE);
		}
		
		// for non-default locale, stringID is augmented with locale
		boolean isDefaultLocale = true;
		String localeStringID = stringID;
		if (!isNullOrEmptyString(locale) && !locale.equalsIgnoreCase(DEFAULT_LOCALE)) {
			isDefaultLocale = false;
			localeStringID += "_" + locale;			// stringID_ch
		}

		// try getting the local string from hash
		String localString = hash.get(localeStringID);
		
		// for non-default locale, I may have to get the String now from message file
		if (localString == null) {
			if (!isDefaultLocale) {
				// read the string from locale string file now
				localString = getStringFromFile(stringType, locale, stringID);
			}
			else {
				//l.error("StringUtil.getLocalString() String [" + stringID + "] not found in hash.");
				return stringID;	// don't return null
			}
		}

		// replace the variables
		int idx = 0;
		for (String var : vars) {
			localString = localString.replace("$var"+idx, var);		// $var0, $var1, ...
		}
		return localString;
	}

	private static HashMap<String, String> fillStringHash(int stringType, String locale)
	{
		try {
			File stringFile;
			HashMap<String,String> hash;
			if (stringType == TYPE_LABEL) {
				// label
				stringFile = new File(RESOURCE_FILE_PATH + "/" + locale + "/" + LABEL_FILENAME);
				hash = _labelHash = putResourceInHash(stringFile);
			}
			else {
				// message
				stringFile = new File(RESOURCE_FILE_PATH + "/" + locale + "/" + MESSAGE_FILENAME);
				hash = _messageHash = putResourceInHash(stringFile);
			}
	    	return hash;
		}
		catch (IOException e) {
			l.error("StringUtil.fillStringHash() failed to fill Type [" + stringType + "] hash.  "
					+ e.getMessage());
			return null;
		}
	}

	/**
	 * Put default resource file in hash
	 * @param resourceFile
	 * @return
	 * @throws IOException
	 */
	public static HashMap<String, String> putResourceInHash(File resourceFile)
		throws IOException
	{
    	
		HashMap<String, String> resourceHash = new HashMap<String,String> (100);
		
		l.info("putResourceInHash(" + resourceFile.getPath() + ") starts");
		processStringFile(resourceFile, resourceHash, null, null);

		l.info("putResourceInHash() completes with " + resourceHash.size() + " records.");
		return resourceHash;
	}	// END: putResourceInHash()

	private static String getStringFromFile(int stringType, String locale, String stringID)
	{
		// get String directly from file and put it in hash
		try {
			File stringFile;
			if (stringType == TYPE_LABEL) {
				// label
				stringFile = new File(RESOURCE_FILE_PATH + "/" + locale + "/" + LABEL_FILENAME);
			}
			else {
				// message
				stringFile = new File(RESOURCE_FILE_PATH + "/" + locale + "/" + MESSAGE_FILENAME);
			}

			// start looking up stringID
			return processStringFile(stringFile, null, locale, stringID);
		}
		catch (IOException e) {
			l.error("StringUtil.getStringFromFile() got IOException when finding String ["
					+ stringID + "] for locale [" + locale + "].  "
					+ e.getMessage());
			return null;
		}
	}
	
	/**
	 * Either lookup a String or fill a hash with the string file
	 * @param stringFile
	 * @param hash
	 * @return
	 */
	private static String processStringFile(File stringFile, HashMap<String,String> hash,
			String locale, String targetStringID)
		throws IOException
	{
		String inputLine=null, resIdS, resMsg=null, hashResIdS;
		int lineNum=0, idx1, idx2, idx3;
		
		HSSFWorkbook wb;
		HSSFSheet sheet = null;
		Iterator<HSSFRow> rows = null;
		InputStream myxls = null;
		BufferedReader in = null;
		
		boolean isCSV = stringFile.getName().toLowerCase().endsWith("csv");
		if (isCSV) {
			in = new BufferedReader(new FileReader(stringFile));
		}
		else {
			myxls = new FileInputStream(stringFile);
			wb = new HSSFWorkbook(myxls);
			sheet = wb.getSheetAt(0);       // first sheet
			rows = sheet.rowIterator();
		}
		
		boolean bFoundTargetString = false;
		while ((inputLine = getALine(isCSV, in, rows)) != null) {
			lineNum++;
			inputLine = inputLine.trim();
			if (inputLine.length()<=0 || inputLine.charAt(0)=='#') continue;
			resMsg = null;
			
			// extract the resource ID (resIdS)
			idx1 = inputLine.indexOf(',');
			if (idx1 == -1) {
				l.warn("   line " + lineNum + " missing comma [" + inputLine + "]");
				continue;
			}
			resIdS = inputLine.substring(0, idx1).trim();
			if (locale!=null && !locale.equals(userinfo.DEFAULT_LOCALE))
				hashResIdS = resIdS + "_" + locale;
			else
				hashResIdS = resIdS;
			
			// check to see if the key has been defined in the file already
			if (hash !=null && (resMsg=hash.get(hashResIdS)) != null) {
				l.warn("   line " + lineNum + " defines a duplicate key "
						+ hashResIdS + " [" + inputLine + "]");
				if (targetStringID!=null && targetStringID.equalsIgnoreCase(resIdS)) {
					return resMsg;	// just return the requested string
				}
				else {
					continue;		// no need to store in hash again, keep going
				}
			}
			
			// extract the resource message bounded by double-quotes
			idx2 = inputLine.indexOf('"', idx1+1);
			if (idx2 == -1) {
				l.warn("   line " + lineNum + " missing open double-quote [" + inputLine + "]");
				continue;
			}
			idx3 = inputLine.indexOf('"', ++idx2);
			if (idx3 == -1) {
				l.warn("   line " + lineNum + " missing close double-quote [" + inputLine + "]");
				continue;
			}
			resMsg = inputLine.substring(idx2, idx3);
			
			// store the string in hash
			if (hash != null) {
				hash.put(hashResIdS, resMsg);
			}
			
			// string lookup only?
			if (targetStringID!=null && targetStringID.equalsIgnoreCase(resIdS)) {
				// the caller is looking up for the targetStringID
				// found it and return
				bFoundTargetString = true;
				break;		// ready to return resMsg
			}
		}	// END while processing line by line
		
		// if I got here that means I didn't find the targetStringID
		if (!bFoundTargetString) resMsg = targetStringID;
		
		// close file
		if (isCSV)
			in.close();
		else
			myxls.close();
		
		return resMsg;
	}	// END: processStringFile()

	private static String getALine(boolean isCSV, BufferedReader in,
			Iterator rows)
	{
		String inputLine = "";
		if (isCSV) {
			try {
				inputLine = in.readLine();
			}
			catch (IOException e) {
				l.error("Exception in getALine()");
				e.printStackTrace();
				return null;
			}
		}
		else {
			if (rows.hasNext()) {
				inputLine = getRowAsCSV((HSSFRow)rows.next());
			}
			else {
				// finish processing the sheet
				return null;
			}
		}
		return inputLine;
	}

	private static String getRowAsCSV(HSSFRow row) {
		// read a row from the Excel file and convert it to CSV format
		String s;
		StringBuffer sBuf = new StringBuffer(512);
		
		for (int i=0; i<3; i++) {
			// currently we only use two cells, but allow more and stop whenever I hit a blank cell
			if (row.getLastCellNum() < i) break;// no more cell

			HSSFCell cell = row.getCell((short)i);
			if (cell == null) break;			// empty cell
			s = cell.toString().trim();
			if (s.length() <= 0)  break;		// hit empty cell, assume no more, return

			// make sure to have double quote to cell string except the first cell
			if (i>0 && s.charAt(0)!='"') {
				s = '"' + s + '"';
			}
			if (i > 0) sBuf.append(",");	// comma separated
			sBuf.append(s);
		}
		return sBuf.toString();
	}

	/**
	 * isNullString()
	 * @param s
	 * @return
	 */
	public static boolean isNullString(String s)
	{
		return s==null || s=="" || s.equals("null");
	}

	/**
	 * isNullOrEmptyString()
	 * @param s
	 * @return
	 */
	public static boolean isNullOrEmptyString(String s)
	{
		return isNullString(s) || s.trim().length()<=0;
	}
	
	/**
	 * isInteger()
	 * @param s
	 * @return
	 */
	public static boolean isInteger(String s)
	{
		try {
			Integer.parseInt(s);
			return true;
		}
		catch (Exception e) {}
		return false;
	}
	
	public static boolean isMultiByte(String s)
	{
		char [] c_array = s.toCharArray();
		boolean result = false;
		String c_str;
		byte [] c_byte_array;
		
		for (char c : c_array) {			
			c_str = Character.toString(c);
			try {c_byte_array = c_str.getBytes("UTF-8");}
			catch (UnsupportedEncodingException e) {
				e.printStackTrace();
				return false;
			}
			
			if (c_byte_array.length > 1) {
				// found multi-byte character
				result = true;
				break;
			}
		}
		return result;
	}

	/**
	 * 
	 * @param omfObj
	 * @param attrName
	 * @return
	 * @throws PmpException
	 */
	public static String getUTFstring(PstAbstractObject omfObj, String attrName)
		throws PmpException
	{
		String bText;
		Object bTextObj = omfObj.getAttribute(attrName)[0];
		if (bTextObj != null)
			try {bText = new String((byte[])bTextObj, "utf-8");}
			catch (UnsupportedEncodingException e) {
				throw new PmpException(e.getMessage());
			}
		else
			bText = "";
		return bText;
	}

	/**
	 * toStringArray
	 */
	public static String [] toStringArray(String str, String regex)
	{
		if (isNullOrEmptyString(str)) return new String[0];
		String [] sa = str.split(regex);
		return sa;
	}
	
	/**
	 * toString: convert array to String separated by delimiter
	 */
	public static String toString(Object [] arr, String delim)
	{
		String s;
		if (arr==null || arr.length<=0) return "";
		
		StringBuffer buf = new StringBuffer();
		if (delim == null) delim = ";";				// default delimiter
		
		for (int i=0; i<arr.length; i++) {
			if (arr[0] instanceof Integer) {
				s = arr[i].toString();
			}
			else s = (String) arr[i];				// assume it is String
			buf.append(s + delim);
		}
		return buf.toString();
	}
	
	public static String toString(int [] arr, String delim) {return toString(Util3.toInteger(arr), delim);}
}
