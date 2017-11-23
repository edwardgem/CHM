//
//	Copyright (c) 2006, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: Util.java
//	Author: AGQ
//	Date:	06/16/06
//	Description: Search engine utils that performs task to manipulate data.
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
package mod.se;

import javax.servlet.http.HttpServletRequest;

import mod.se.filehandler.Handler;
import mod.se.filehandler.HandlerDOC;
import mod.se.filehandler.HandlerHTML;
import mod.se.filehandler.HandlerPDF;
import mod.se.filehandler.HandlerPPT;
import mod.se.filehandler.HandlerXLS;
import mod.se.filehandler.HandlerZIP;
import oct.codegen.query;
import oct.codegen.result;

import org.apache.log4j.Logger;

import util.PrmLog;

public class Util {
	static final String INDEX = util.Util.getPropKey(SEConstants.PST, SEConstants.SE_INDEX_PATH);
	static final String EXT = "/ext";
	static Logger l = PrmLog.getLog();

	public static String constructExpression(HttpServletRequest request, String category) {
		// construct expression
		StringBuffer sb = new StringBuffer();

		String projName = request.getParameter("projName");
		String fromDate = request.getParameter("FromDate");
		String toDate = request.getParameter("ToDate");
		String postName = request.getParameter("postName");
		String accessName = request.getParameter("accessName");

		// Default for files
		String createdDate = "CreatedDate";
		String owner = "Owner";

		if (category == null)
			category = query.CAT_FILE;
		else if (category.equalsIgnoreCase(query.CAT_BLOG)) {
			owner = "Creator";

			// blog type
			String s, tempExpr;
			String [] blogType = {result.TYPE_BUG_BLOG, result.TYPE_TASK_BLOG, result.TYPE_ACTN_BLOG};
			int count = 0;

			tempExpr = "";
			for (int i=0; i < blogType.length; i++)
			{
				s = request.getParameter(blogType[i]);
				if (s!=null && s.length()>0)
				{
					if (tempExpr.length() > 0) tempExpr += " || ";
					tempExpr += "Type='" + blogType[i] + "'";
					count++;
				}
			}
			if (count >= blogType.length) tempExpr = "";		// select all types: optimize to no proj phase
			if (tempExpr.length() > 0)
			{
				tempExpr = "(" + tempExpr + ")";
				if (sb.length() > 0) sb.append(" && ");
				sb.append(tempExpr);
			}
			if (tempExpr.length() == 0)
			{
				if (sb.length() > 0) sb.append(" && ");
				sb.append("(Type!='" + result.TYPE_ENGR_BLOG + "')");
			}
			sb.append(" && (Type!='*" + result.TYPE_ARCHIVE + "')");	// ignore all archive blog for now
			sb.append(" && (Type!='Task-Archive')");
			sb.append(" && (Type!='Bug-Archive')");
			sb.append(" && (Type!='Personal-Archive')");
			sb.append(" && (Type!='Action-Archive')");
		}
		else if (category.equalsIgnoreCase(query.CAT_MINUTE)) {
			owner = "Recorder";
			createdDate = "StartDate";
		}

		if (projName!=null && projName.trim().length()>0) {
			if (sb.length() > 0)
				sb.append(" && ");
			sb.append("(ProjectID='"+projName+"')");
		}

		if (fromDate!=null && fromDate.trim().length() > 0 && !fromDate.equals("- -")) {
			if (sb.length() > 0)
				sb.append(" && ");
			String dateS = util.Util.formatToDate("MM/dd/yy", fromDate, "yyyy.MM.dd");
			sb.append("("+createdDate+">='"+dateS+"')");
		}

		if (toDate!=null && toDate.trim().length() > 0 && !toDate.equals("- -")) {
			if (sb.length() > 0)
				sb.append(" && ");
			String dateS = util.Util.formatToDate("MM/dd/yy", toDate, "yyyy.MM.dd");
			sb.append("("+createdDate+"<='"+dateS+"')");
		}

		if (postName!=null && postName.trim().length() > 0) {
			if (sb.length() > 0)
				sb.append(" && ");
			sb.append("("+owner+"='"+postName+"')");
		}

		if (category.equalsIgnoreCase(query.CAT_FILE) && accessName!=null && accessName.trim().length() > 0) {
			if (sb.length() > 0)
				sb.append(" && ");
			sb.append("(ViewBy='%"+accessName+"'%)");	// ECC: changed attribute AccessedBy to ViewBy
		}

		return sb.toString();
	}

	public static String createCachePath(String fileLocation) {
		String cachePath;
		if (util.Util.isAbsolutePath(fileLocation)) {
			int idx = 2; // Index of c:
			// server path requires an extra '/'
			if (fileLocation.length()>idx && fileLocation.charAt(idx) != '/')
				idx = 1;
			cachePath = INDEX + EXT + fileLocation.substring(idx);
		}
		else
			cachePath = INDEX + fileLocation;
		return cachePath;
	}

	/**
	 * Determines the extension on the current filename
	 * and returns the corresponding FileHandler type.
	 * @param fileLocation
	 * @return
	 */
	public static Handler getFileType(String fileLocation) {
		int extensionIdx = fileLocation.lastIndexOf(".");

		if (extensionIdx > 0) {
			String extension = fileLocation.substring(extensionIdx).toLowerCase();
System.out.println("--- checking file type: " + extension);
			if (extension.equals(SEConstants.PDF))
				return new HandlerPDF(fileLocation);
			else if (extension.equals(SEConstants.DOC))
				return new HandlerDOC(fileLocation);
			else if (extension.equals(SEConstants.PPT))
				return new HandlerPPT(fileLocation);
			else if (extension.equals(SEConstants.XLS))
				return new HandlerXLS(fileLocation);
			else if (extension.equals(SEConstants.HTML) ||
					extension.equals(SEConstants.HTM))
				return new HandlerHTML(fileLocation);
			else if (extension.equals(SEConstants.ZIP))
				return new HandlerZIP(fileLocation);
			else
				return new Handler(fileLocation);
		}
		else {
			l.warn("Cannot find ext for: " + fileLocation);
			return new Handler(fileLocation);
		}
	}

	public static String removeBadChar(String query) {
		if (query != null) {
			// remove beginning *, ?
			StringBuffer sb = new StringBuffer();
			boolean isSpace = true;
			for (int i=0; i<query.length(); i++) {
				char character = query.charAt(i);
				if (character == '*' || character == ' ' || character == '?') {
					if (!isSpace) {
						sb.append(character);
						if (character == ' ')
							isSpace = true;
					}
				}
				else {
					sb.append(character);
					isSpace = false;
				}
			}
			return sb.toString();
		}
		else
			return null;
	}

	public static String escapeRegExpChar(String s) {
		if (s != null && s.length() > 0) {
			StringBuffer sb = new StringBuffer();
			int length = s.length();
			char curChar;
			for (int i=0; i<length; i++) {
				curChar = s.charAt(i);
				switch (curChar) {
				case '(':
				case ')':
				case '+':
				case '{':
				case '}':
				case '[':
				case ']':
				case '?':
				case '*':
					sb.append('\\');
				default:
					sb.append(curChar);
				}
			}
			s = sb.toString();
		}
		return s;
	}

	public static String searchPath(String query) {
		if (query != null) {
			return query + " filename: (" + query + ")";
		}
		else
			return null;
	}
}
