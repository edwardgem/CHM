//
///////////////////////////////////////////////////////////////////////////////////////////
//
//	File:		PrmClientConstant.java
//	Author:		ECC
//	Date:		08/18/2008
//	Description:
//				To enable download of shared files from the server to client machine.
//				It first calls the server to get a number of files the user has on
//				the share file list.  Allowing the user to choose from there and then
//				download those selected files.
//
//				Since I don't have the user interface now, I will simply do both in one
//				call and don't allow user to choose.  Just download all shared files.
//
//	Modification:
//				@ECC113009	Introduce new calling convention in order to support a better
//				progress bar.  First call prepareUploadFile() then call uploadSegment().
//
///////////////////////////////////////////////////////////////////////////////////////////
//

package oct.util.file;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;

public class PrmClientConstant
{
	public static final String VERSION			= "CR Remote Access Ver. 1.7.02";
	public static final String SPEC_PATH		= "cr.properties";
	public static final String FILENAME_LABEL 	= "filename";
	public static final String TIME_LABEL		= "time";
	public static final String PATH_LABEL		= "path";
	public static final String DEPT_LABEL		= "dept";
	public static final String REMOVE_LABEL		= "remove";
	public static final String USER_LABEL		= "user";
	public static final String UPLOAD_OPT_LABEL	= "upload_option";
	public static final String UP_OPT_BACKUP	= "REMOTE_BACKUP";
	public static final String UP_OPT_TOPROJ	= "UPLOAD_TO_PROJECT";
	public static final String PROJ_LABEL		= "project";
	public static final String TASK_LABEL		= "task";
	public static final String ATTID			= "attId";
	
	public static final String LOGFILE_NAME		= ".crlog";
	public static final String RECALSP_LABEL	= "RECALSPACE";
	public static final String DRIVE_STR		= "-drive";
	public static final String DEPT_TERM		= "?@";
	public static final String TERMINATOR1		= "::";
	public static final String TERMINATOR2		= ":@:";

	public static final String SIZE_TERM		= "?#";
	public static final String ATTR_BACKUP		= "Backup";
	
	public static final String OP_LABEL			= "op";
	public static final String OP_GET_SHARE		= "GET_SHARE";
	public static final String OP_DOWNLOAD		= "DOWNLOAD";
	
	// @ECC113009
	public static final String OP_GET_SEGMENT		= "GET_SEGMENT";
	public static final String OP_DOWNLOAD_SEGMENT	= "DOWNLOAD_SEGMENT";
	
	public static final String FILEID_LABEL 	= "fid";
	public static final String CHUNK_LABEL		= "chunk";
	
	public static final String ERROR			= "PrmError";
	public static final String GET_PROJLIST_LABEL = "GETPROJLIST_LABEL";
	public static final String GET_TASKLIST_LABEL = "GETTASKLIST_LABEL";
	
	public static int DOWNLOAD_CHUNK_SIZE		= 1 * 1024 * 1024;
	public static int UPLOAD_CHUNK_SIZE			= 1 * 1024 * 1024;

	// allow the client to set the location of the cr.properties file
	// by calling setPropFile()
	private static String _propertiesFile = null;

	public static void setPropFile(String fn) {_propertiesFile = fn;}

	public static String getPropFile()
	{
		if (_propertiesFile != null)
			return _propertiesFile;

		_propertiesFile = SPEC_PATH;
		return _propertiesFile;
	}

	public static String getXMLValue(String fName, String tag)
	{
		// open the properties file and extract the value of the tag
		try
		{
			File f = new File(fName);			// cr.properties
			if (fName==null || !f.exists())
				return null;					// on server side there is no cr.properties
			FileInputStream in = new FileInputStream(f);
			BufferedReader din = new BufferedReader(new InputStreamReader(in));
			String line, res = "";
			boolean bFound = false;
			int idx;
			
			// ECC: debug
			tag = tag.toUpperCase();
			if (tag.equalsIgnoreCase("location"))
				return f.getAbsolutePath();
	
			String begTag = "<" + tag + ">";
			String endTag = "</" + tag + ">";
			int tagLen = begTag.length();
			

			while ((line = din.readLine()) != null)
			{
				line = line.trim();
				if ((line.length() <= 0) || (line.charAt(0) == '#'))
					continue;						// comment line and blank line

				if (bFound || (line.length()>=tagLen && line.substring(0,tagLen).equalsIgnoreCase(begTag)) )			// <UPLOAD>
				{
					// found the tag, start extracting multiple lines
					if (!bFound)
					{
						// begin tag, might have some content, need to extract the rest of the line
						line = line.substring(tagLen);
						if ((idx = line.indexOf(endTag)) != -1)
						{
							// found end tag, extract content and done
							res = line.substring(0, idx).trim();
							break;			// done
						}
						else
						{
							// no end tag, just return the rest of the line
							bFound = true;
							res = line.trim();
						}
					}
					else
					{
						// it is extracting lines after tag
						if ((idx = line.indexOf(endTag)) != -1)
						{
							// found end tag
							if (idx > 0)
							{
								// more content followed by end tag
								if (res.length() > 0)
									res += PrmClientConstant.TERMINATOR1;
								res += line.substring(res.length()).trim();
							}
							break;
						}
						else
						{
							// a content line, just extract
							if (res.length() > 0)
								res += PrmClientConstant.TERMINATOR1;
							res += line.trim();
						}
					}
				}
			}
			din.close();
			return res;
		}
		catch (IOException e) {e.printStackTrace(); return null;}
	}	// END: getXMLValue()
	
	// open the properties file and set the value
	public static void setXMLvalue(String fName, String key, String value)
	{	
		// check to see if the key is already present in the file, if so, simply replace the
		// value, otherwise append the key/value pair to the end
		BufferedReader din = null;
		BufferedWriter dout= null;
		
		try
		{
			File f = new File(fName);						// cr.properties
			FileInputStream in = new FileInputStream(f);
			din = new BufferedReader(new InputStreamReader(in));
			File newFile = new File("tempFile");
			FileOutputStream fos = new FileOutputStream(newFile);
			dout = new BufferedWriter(new OutputStreamWriter(fos));
			String line, originalLine;
			boolean bDone = false;
			
			// begin tags are always in the beginning of the line
			String begTag = "<" + key.toUpperCase() + ">";
			int tagLen = begTag.length();
			String endTag = "</" + key.toUpperCase() + ">";
			
			while ((line = din.readLine()) != null)
			{
				originalLine = line;
				line = line.trim().toUpperCase();
				if (bDone || (line.length() <= 0) || (line.charAt(0) == '#'))
				{
					// either copying lines after we are done or it is comment/blank
					dout.write(originalLine + "\n");
					continue;						// comment line and blank line
				}

				if ((!bDone && line.length()>=tagLen && line.substring(0,tagLen).equals(begTag)))			// <UPLOAD>
				{				
					// extract info behind
					if (line.endsWith(endTag))
					{
						// replace the line and we are done: just need to copy the rest of the file
						bDone = true;
						dout.write(begTag + value + endTag + "\n");
					}
					else
					{
						// need to replace multiple lines until the end tag on a new line
						// 1. write begin tag
						dout.write(begTag);
						
						// 2. extract info after begin tag line
						if (line.length() > tagLen)
						{
							dout.write(originalLine.substring(tagLen) + "\n");
						}
						
						// 3. skipping old value lines until endTag
						while ((line=din.readLine()) != null)
						{
							if (line.startsWith(endTag))
							{
								// found it!
								bDone = true;
								dout.write(value + "\n");
								dout.write(endTag + "\n");
								break;
							}
						}
						if (bDone) break;	// done, just need to copy the rest of the file
						else
						{
							// somehow I don't find the end tag, just return
							return;
						}
					}
				}
				else
				{
					// another line, just copy
					dout.write(originalLine + "\n");
				}
			}	// END: while loop
			if (!bDone)
			{
				// the tag is not found in the file
				if (!value.contains("\n"))
				{
					dout.write(begTag + value + endTag + "\n");
				}
				else
				{
					dout.write(begTag + "\n");
					dout.write(value + "\n");
					dout.write(endTag + "\n");
				}
			}
			dout.close();
			din.close();
			f.delete();
			newFile.renameTo(f);		// replace the old cr.properties file
		}
		catch (IOException e) {e.printStackTrace();}
		finally
		{
			try
			{
				din.close();
				dout.close();
			}
			catch (IOException e) {}
		}
	}
}
