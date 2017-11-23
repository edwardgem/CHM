//
//	Copyright (c) 2010 EGI Technologies.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
// $Header$
//
//	File:	$RCSfile$
//	Author:	ECC
//	Date:	$Date$
//  Description:
//      Servlet to redirect circle forum access to JSP
//
/////////////////////////////////////////////////////////////////////

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import util.Util;

public class CircleRedirect extends HttpServlet
{
   	/**
	 * 
	 */
	private static final long serialVersionUID = -6813783801370777554L;
	static final String HOST = Util.getPropKey("pst", "PRM_HOST");

	protected void doGet(HttpServletRequest request,
						 HttpServletResponse response)
		throws ServletException, IOException
	{

		try {
			// get circle name
			String fullURL = request.getRequestURI();
			while (fullURL.endsWith("/"))
				fullURL = fullURL.substring(0, fullURL.length()-1);		// remove ending "/"
			System.out.println("***** url="+fullURL);
			int idx = fullURL.lastIndexOf("/");
			String circleName = "";
			if (idx != -1) {
				circleName = fullURL.substring(idx+1);
			}

			// redirect to jsp
			String url = HOST + "/network/circle_visitor.jsp?cir=" + circleName;
			response.sendRedirect(url);
		}
		catch (Exception e) {
			String msg = e.getMessage();
			System.out.println("Error in CircleRedirect.doGet(): " + msg);
			e.printStackTrace();
		}
	}

	protected void doPost(HttpServletRequest arg0, HttpServletResponse arg1)
		throws ServletException, IOException
	{
		doGet(arg0, arg1);
	}

}
