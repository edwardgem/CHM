
//
//	Copyright (c) 2015, EGI Technologies, Inc..  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	ResolveRole.java
//	Author:	ECC
//	Date:	03/19/16
//  Description:
//      User created method to resolve role.
//
/////////////////////////////////////////////////////////////////////

package util;
import oct.codegen.userManager;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;

public class ResolveRole
{
	private Logger l = PrmLog.getLog();
	
	public int [] getHRStaff(PstUserAbstractObject pstuser)
	{
		try
		{
			// XOR to get HR staff: anyone with DepartmentName='HR' and Title!='GM' (or with no Title)
			userManager uMgr = userManager.getInstance();
			int [] ids = uMgr.findId(pstuser, "DepartmentName='HR'");
			int [] ids1 = uMgr.findId(pstuser, "DepartmentName='HR' && Title='GM'");
			
			//System.out.println("all=" + ids.length + ", GM="+ids1.length);
			ids = Util2.outerJoin(ids, ids1);		// XOR to get IT people but not the GM
			

			l.info(">>> Plugin class ResolveRole.getHRStaff() found " + ids.length);
			return ids;

		}
		catch(Exception e)
		{
			e.printStackTrace();
			l.error(">>> Plugin class ResolveRole.getHRStaff() failed!");
			return null;
		}
	}	// END: getYWBStaff
	
	
	public int [] getYWBStaff(PstUserAbstractObject pstuser)
	{
System.out.println(">>>>   calling getYWBStaff()");
		try
		{
			// XOR to get YWB staff: anyone with DepartmentName='YWB' and Title!='GM' (or with no Title)
			userManager uMgr = userManager.getInstance();
			int [] ids = uMgr.findId(pstuser, "DepartmentName='YWB'");
			int [] ids1 = uMgr.findId(pstuser, "DepartmentName='YWB' && Title='GM'");
			
			//System.out.println("all=" + ids.length + ", YWB="+ids1.length);
			ids = Util2.outerJoin(ids, ids1);		// XOR to get YWB people but not the GM
			

			l.info(">>> Plugin class ResolveRole.getYWBStaff() found " + ids.length);
			return ids;

		}
		catch(Exception e)
		{
			e.printStackTrace();
			l.error(">>> Plugin class ResolveRole.getYWBStaff() failed!");
			return null;
		}
	}	// END: getYWBStaff

}
