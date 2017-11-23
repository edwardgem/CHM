////////////////////////////////////////////////////
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	PrmMonitor.java
//	Author:	ECC
//	Date:	10/12/04
//	Description:
//		Run background processes for PRM.
//
//	Modification:
//		@060106ECC	PrmMonitor will now restart PrmThread if the thread is dead prematurely.
//		@090911ECC	Added mercurial repository for edward.cheng
//
////////////////////////////////////////////////////////////////////

package main;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;

import util.Prm;

public class PrmMonitor extends HttpServlet
{

	/**
	 * 
	 */
	private static final long serialVersionUID = 4723489701205814721L;
	
	private static PrmThread thisMonitor = null;

	public void init(ServletConfig config) throws ServletException
	{
		try
		{
			if (thisMonitor != null) {
				System.out.println("!! PrmMonitor already started!  Exit!");
				return;
			}
			super.init(config);
			Prm.setInitParameters();
			System.out.println("*** starting PrmMonitor for [" + Prm.getAppTitle() + "]");
			thisMonitor = new PrmThread("PrmMonitor");
			thisMonitor.start();
		}
		catch (Exception e)
		{
			System.out.println(e.toString());
			e.printStackTrace();
			throw new ServletException();
		}

	}
}
