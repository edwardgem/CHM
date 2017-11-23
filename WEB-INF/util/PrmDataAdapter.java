////////////////////////////////////////////////////
//	Copyright (c) 2006, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	PrmDataAdapter.java
//	Author:	ECC
//	Date:	09/12/07
//	Description:
//		Implementation of PrmDataAdapter.java class.
//		PrmDataAdapter uses an instruction file of a certain tool context to process a datalog file.
//		The instructions of various tool contexts are stored in a file specified in pst.properties, FILE_CONTEXT_SPEC.
//		According to the instructions in the spec file, the datalog is processed and massaged data is returned
//		by PrmDataAdapter to the caller as a string.
//
//	Modification:
//
//
////////////////////////////////////////////////////////////////////

package util;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.InputStreamReader;

import org.apache.log4j.Logger;

/**
 * @author edwardc
 *
 */
public class PrmDataAdapter {
	final static String NEW_LINE		= "\n";

	final static String OPS_FIND		= "find";
	final static String OPS_SKIP		= "skip";
	final static String OPS_PRINT		= "print";
	final static String OPS_WHILE		= "while";
	final static String OPS_WHILE_END	= "/while";

	final static int OP_FIND			= 10;
	final static int OP_SKIP			= 15;
	final static int OP_WHILE			= 20;
	final static int OP_WHILE_END		= 21;
	final static int OP_PRINT			= 35;

	final static int MAX_PRINT_FIELD	= 10;
	final static int MAX_SIZE_OF_LOOP	= 8192;		// total char allowed within While loop instruction
	final static int LAST_FIELD			= 999;		// denote last field in the data line

	static Logger l = PrmLog.getLog();

	/////////////////////////////////////////////////////////////////////////////////////
	// public callable to process a datalog file according to the tool context file.
	// return the resulted massaged string.
	//
	public static String processDatalog(String datalogFile, String tag)
		throws Exception
	{
		String instFile = Util.getPropKey("pst", "FILE_CONTEXT_SPEC");
		if (instFile == null)
		{
			l.error("FILE_CONTEXT_SPEC is not specified in pst.properties.");
			return null;
		}
		
		FileInputStream datalog = new FileInputStream(datalogFile);		// datalog
		FileInputStream spec = new FileInputStream(instFile);			// processing spec

		BufferedReader datalogIn	= new BufferedReader(new InputStreamReader(datalog));
		BufferedReader specIn		= new BufferedReader(new InputStreamReader(spec));

		// process the datalog based on the spec instructions
		String result = process(datalogIn, specIn, tag);
		datalogIn.close();
		spec.close();
		
		return result;
	}	// END: processDatalog()
	
	
	/////////////////////////////////////////////////////////////////////////////////////
	private static String search(BufferedReader iFile, String searchS)
		throws Exception
	{
		String line;
		while ((line = iFile.readLine()) != null)
		{
			line = line.trim();
			if (line.indexOf(searchS) != -1)
			{
				return line;			// found search text, return the line
			}
		}
		return null;		// cannot find the search text, return null
	}	// END: search()


	/////////////////////////////////////////////////////////////////////////////////////
	private static int getOpcode(String line, String [] param)
	{
		// this is an instruction line
		// the line must starts with one of the followings:
		// <find, <skip, <print
		if (line.charAt(0) != '<')
			return -1;

		//System.out.println("getOpcode(): " + line);

		int op = 0;
		int idx1, idx2;
		String s;
		String [] sa;
		line = line.substring(1);

		if (line.startsWith(OPS_FIND))
		{
			//////////////////////////////////////////////
			// param[0] will store the search string
			op = OP_FIND;
			idx1 = line.indexOf(">");	// <find>
			idx2 = line.indexOf("</" + OPS_FIND);
			param[0] = line.substring(idx1+1, idx2);
			//System.out.println("debug: FIND string is [" + param[0] + "]");
		}
		else if (line.startsWith(OPS_SKIP))
		{
			//////////////////////////////////////////////
			// param[0] will store the # of lines to be skipped
			op = OP_SKIP;
			idx1 = line.indexOf(">");	// <skip>
			idx2 = line.indexOf("</" + OPS_SKIP);
			param[0] = line.substring(idx1+1, idx2).trim();
			//System.out.println("debug: SKIP number is [" + param[0] + "]");
		}
		else if (line.startsWith(OPS_PRINT))
		{
			//////////////////////////////////////////////
			// param[0] specifies total no. of fields to be printed, param[x] will store the field contents
			op = OP_PRINT;
			idx1 = line.indexOf(">");	// <skip>
			idx2 = line.indexOf("</" + OPS_PRINT);
			s = line.substring(idx1+1, idx2).trim();
			sa = s.split(" ");
			if (sa.length > MAX_PRINT_FIELD)
			{
				l.info("Error in processing data adapter.  Exceed total no. of print fields allowed [" + sa.length + "]");
				return -1;
			}
			param[0] = String.valueOf(sa.length);
			for (int i=0; i<sa.length; i++)
				param[i+1] = sa[i].trim();				// could be $0, $1, $2, ..., $$
			/*System.out.print("debug: PRINT " + param[0] + " fields:");
			for (int i=0; i<sa.length; i++) System.out.print(" " + param[i+1]);
			System.out.println("");*/
		}
		else if (line.startsWith(OPS_WHILE))
		{
			//////////////////////////////////////////////
			// while needs a condition, use param to store it.  Only support matching of string at this point
			// param[0] stores field ($3, etc.); param[1] stores the matching value (e.g. mV)
			op = OP_WHILE;
			idx1 = line.indexOf(">");	// <while ... >
			s = line.substring(5, idx1).trim();
			sa = s.split("=");
			param[0] = sa[0].trim();					// could be $0, $1, ..., $$
			s = sa[1].trim();							// e.g. "xyz"
			if (s.charAt(0)=='"' && s.charAt(s.length()-1)=='"')
				s = s.substring(1, s.length()-1);
			param[1] = s;								// just the string, e.g. xyz
		}
		else if (line.startsWith(OPS_WHILE_END))
		{
			//////////////////////////////////////////////
			op = OP_WHILE_END;
		}

		//System.out.println("done getOpcode()");
		return op;
	}	// END: getOpcode()


	/////////////////////////////////////////////////////////////////////////////////////
	private static String process(BufferedReader dataFile, BufferedReader specFile, String tag)
		throws Exception
	{

		// read spec file and follow its instruction to process inFile
		String s;
		String searchS = "<" + tag + ">";
		String instLine;
		String dataLine = "";
		StringBuffer sBuf = new StringBuffer();
		boolean foundTag = false;

		while ((instLine = specFile.readLine()) != null)
		{
			instLine = instLine.trim();
			if (instLine.startsWith(searchS))
			{
				foundTag = true;
				break;			// found tag
			}
		}
		if (!foundTag) return "";	// end of file

		// I should be sitting on the tag line: e.g. <AG>
		int op = 0;
		String [] param = new String[MAX_PRINT_FIELD+1];
		String [] sa;
		int count, idx;

		// for looping, need to remember condition to be used for every dataLine following
		boolean bLoop = false;		// are we processing a while loop?
		int loopMatchFieldNum = 0;
		String loopMatchString = "";

		while ((instLine = specFile.readLine()) != null)
		{
			instLine = instLine.trim();
			if (instLine.length()<=0 || instLine.charAt(0)=='#')
				continue;		// skip blank and comment lines

			if (instLine.startsWith("</" + tag + ">"))
			{
				//System.out.println("*** found end tag: done with process()");
				return sBuf.toString();			// ***** done
			}

			dataLine = dataLine.trim();			// need to trim dataLine before processing
			// System.out.println(">>> " + dataLine);

			// check to see if we are in a loop, if so, condition must be met before processing
			if (bLoop)
			{
				// the loop condition we support now is only matching of string
				sa = dataLine.split(" ");
				if (loopMatchFieldNum == LAST_FIELD)
					s = sa[sa.length-1].trim();
				else
					s = sa[loopMatchFieldNum].trim();
				if (!s.equals(loopMatchString))
				{
					// no match: we are out of the loop
					// no need to read another dataLine, only need to get beyond the WHILE loop and read another instLine
					bLoop = false;
					instLine = search(specFile, "<" + OPS_WHILE_END + ">");
					continue;		// this will read in another instLine
				}
			}

			op = getOpcode(instLine, param);
			switch (op)
			{
				case OP_FIND:
					/////////////////////////////////////////////
					dataLine = search(dataFile, param[0]);
					break;

				case OP_SKIP:
					/////////////////////////////////////////////
					count = Integer.parseInt(param[0]);
					for (int i=0; i<count; i++)
						dataLine = dataFile.readLine();			// skip lines
					break;

				case OP_PRINT:
					/////////////////////////////////////////////
					// print from the current dataLine
					// param0 = # of fields to be printed
					// param1 through 9 tells either a text or a field in dataLine to be printed
					sa = dataLine.split(" ");
/*
System.out.println("+++ printing dataline: "+dataLine);
System.out.println("sa length = "+sa.length);
for (int i=0; i<sa.length; i++) System.out.print(" " + sa[i]); System.out.println("");
*/
					count = Integer.parseInt(param[0]);
					for (int i=1; i<=count; i++)
					{
						if (param[i].charAt(0) == '$')
						{
							if (param[i].charAt(1) == '$')
								idx = sa.length-1;		// print the last field in the dataLine
							else
								idx = Integer.parseInt(param[i].substring(1));
							sBuf.append(sa[idx] + " ");
						}
						else if (param[i].equals("\\n"))
							sBuf.append(NEW_LINE);
						else
							sBuf.append(param[i] + " ");
					}

					//sBuf.append(NEW_LINE);
					break;

				case OP_WHILE:
					/////////////////////////////////////////////
					specFile.mark(MAX_SIZE_OF_LOOP);	// mark the beginning of command lines
					bLoop = true;
					if (param[0].equals("$$"))
						loopMatchFieldNum = LAST_FIELD;	// denote last field
					else
						loopMatchFieldNum = Integer.parseInt(param[0].substring(1));
					loopMatchString = param[1];
					break;

				case OP_WHILE_END:
					/////////////////////////////////////////////
					// finish processing all loop commands for this dataLine, needs to go to next dataLine and back to
					// the beginning point of the loop command lines
					specFile.reset();					// back to the beginning of command lines
					dataLine = dataFile.readLine();		// get the next line in
					break;

				default:
					// unexpected opcode in spec file
					s = "\nError: unexpected opcode found in spec file\n   " + instLine;
					l.error(s);
					sBuf.append(s);
					return sBuf.toString();
			}	// END switch (op)

			if (dataLine == null)
				return sBuf.toString();

		}	// END while more instructions

		// end tag not found
		l.error("No end tag found in processing data adapter instruction file.");
		sBuf.append("\nError: end tag </" + tag + "> not found.");
		return sBuf.toString();

	}	// END: process

}
