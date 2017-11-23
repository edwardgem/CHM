////////////////////////////////////////////////////
//	Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	PrmLog.java
//	Author:	ECC
//	Date:	07/05/05
//	Description:
//		Use log4j for PRM.
//
//	Modification:
//
//
////////////////////////////////////////////////////////////////////

package util;

import org.apache.log4j.Logger;

public class PrmLog
{
	static Logger logger = Logger.getLogger(PrmLog.class.getName());

	public static Logger getLog() {return logger;}

/*	I am using the default log4j.properties in the axis_lib directory
	public static void init()
	{
		PropertyConfigurator.configure("log.properties");
	}
*/
}
