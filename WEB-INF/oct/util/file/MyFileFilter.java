//
//	Copyright (c) 2005, EGE Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	MyFileFilter.java
//	Author:	ECC
//	Date:	04/03/05
//	Description:	 FilenameFilter that takes a prefix and subfix
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
// MyFileFilter.java : implementation of the MyFileFilter class
//
package oct.util.file;

import java.io.File;
import java.io.FilenameFilter;

public class MyFileFilter implements FilenameFilter
{
	private String prefix;
	private String ext;

	public MyFileFilter(String s1, String s2) {prefix = s1; ext = s2;}
	public boolean accept(File dir, String name)
	{
		return(name.startsWith(prefix) && name.endsWith(ext));
	}
}
