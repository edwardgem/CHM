//
//	Copyright (c) 2009 EGI Technologies Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
// $Header$
//
//	File:	$RCSfile$
//	Author:	ECC
//	Date:	08/18/2008
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
/**
* Interface file for deploying source files from client to server
*/

public interface DeployBase
{
	public static final String OPERATION		= "operation";
	public static final String FILENAME			= "filename";
	public static final String TIMESTAMP		= "timestamp";
	public static final String TRANSFER			= "transfer";
	public static final String TARGETPATH		= "targetPath";
	
	// folder and file (prefix) to be ignored
	public static final String IGNORE_DIR		= // note: use the ";" as the beginning of token
		";MF;memberPic;CVS;top;mid;but;ocm;file;FCKeditor;hgignore;.hg;.hgignore;.metadata;.settings;.project;.classpath;" +
		"PrmExt;old;logo.gif;alert.htm;properties.jar;dataSource.xml;META-INF;" +
		"servlet.jar;servlet-api.jar";		// add ;.java if no java source should be deployed
	// lib;dataSource.xml;properties.jar
	
	public static final int CHECK_FILE			= 1;
	public static final int DEPLOY_FILE		= 2;
}
