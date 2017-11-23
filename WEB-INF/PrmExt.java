//
//	Copyright (c) 2006 EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
// $Header$
//
//	File:	$RCSfile$
//	Author:	Allen G Quan
//	Date:	$Date$
//  Description:
//      Servlet to fetch object information. This servlet reads
//		a PrmExt to determine what type of objects to retreive.
//		According to the specified type and attributes, this servlet
//		will generate an xml of all the information contained in the
//		database. 
//
//  Required:
//		u		- user name
//		p		- user name's password
//		req		- type of req specified in PrmExt.xml
//
//	Optional:
//		param	- req type's object id
//		expr	- Limits the output (%26 = &) 
//					e.g. ProjectID='12345'%26%26Type='Late'
//		project	- Specify the project name
//		
//	Modification:
/////////////////////////////////////////////////////////////////////

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import mod.prmext.PEConstants;
import mod.prmext.PEManager;
import mod.prmext.PEProperty;
import mod.prmext.PEXmlWriter;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.pmp.exception.PmpException;
import oct.pmp.exception.PmpInternalException;
import oct.pst.PstGuest;
import oct.pst.PstUserAbstractObject;

import org.dom4j.Document;

import util.Util;

public class PrmExt extends HttpServlet implements PEConstants{
	
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		
		try {	       
			// get parameters
			String u = request.getParameter(U);
			String p = request.getParameter(P);
			String req = request.getParameter(REQ);
			String param = request.getParameter(PARAM);
			String expr = request.getParameter(EXPR);
			String project = request.getParameter(PROJECT);
			String upload = request.getParameter(UPLOAD);
			
			// trim the A from IDV name SPANSION
			if (project != null && project.length() == 6) {
				if (project.endsWith("A") || project.endsWith("a"))
					project = project.substring(0,5);
			}
			
			// login
			userManager uMgr = userManager.getInstance();
			PstUserAbstractObject gUser = (PstUserAbstractObject) PstGuest.getInstance();
			user pstuser = (user)uMgr.login(gUser, u, p);
			

			if (upload != null) {
				HttpSession s = request.getSession(true);
				user newUser = null;
				PstUserAbstractObject oldUser = null;
				try
				{
					oldUser = (PstUserAbstractObject) PstGuest.getInstance();
				}
				catch (PmpException e)
				{
					e.printStackTrace();
					response.sendRedirect("index.jsp?error=Internal Error! Please check the application server log.");
					return;
				}
				newUser = (user)userManager.getInstance().login(oldUser, u, p); 
				s.setAttribute("pstuser", newUser);
				
				String host = Util.getPropKey("pst", "PRM_HOST");
				response.sendRedirect(host + "/PrmExt/upload.jsp");
			}
			else {
				// get req information from properties file PrmExt.xml
				String prmExtFile = Util.getPropKey(PST, PRM_EXT_FILE);
				PEProperty peProperty = new PEProperty(req, prmExtFile);
				
				// fetch db information
				Document doc = PEManager.getXmlDocument(peProperty, pstuser, param, expr, project);
	
				// log user out and 
				uMgr.logout(pstuser);	
				response.getWriter().write(doc.asXML());
			}			
		} catch (PmpInternalException e) {
			// Bad login
			e.printStackTrace();
			Document doc = createErrorMessage(e.getMessage());
			if (doc != null)
				response.getWriter().write(doc.asXML());
		} catch (Exception e) {
			String message = e.getMessage();
			Document doc = createErrorMessage(message);
			if (doc != null)
				response.getWriter().write(doc.asXML());
			e.printStackTrace();
		}
	}
	
	protected void doPost(HttpServletRequest arg0, HttpServletResponse arg1) throws ServletException, IOException {
		doGet(arg0, arg1);
	}
	
	private Document createErrorMessage(String message) {
		Document doc = null;
		if (message != null) {
			PEXmlWriter peXmlWriter = new PEXmlWriter(PRMEXT);
			peXmlWriter.addToRootElement(ERROR, message);
			doc = peXmlWriter.getDoc();
		}
		return doc;
	}
}
