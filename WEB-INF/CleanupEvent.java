//
///////////////////////////////////////////////////////////////////////////////////////////
//
//	File:		CleanupEvent.java
//	Author:		ECC
//	Date:		10/07/2008
//	Description:
//
//	Modification:
//
///////////////////////////////////////////////////////////////////////////////////////////
//

import oct.codegen.userManager;
import oct.pst.PstGuest;
import util.PrmEvent;

public class CleanupEvent
{

	public static void main(String[] args)
		throws Exception
	{
		if (args.length < 1) {
			System.out.println("Usage: runtool CleanupEvent <evt ID>");
			return;
		}
		
		PstGuest pstuser = PstGuest.getInstance();
		userManager uMgr = userManager.getInstance();
		
		for (int num=0; num<args.length; num++) {
			String evtIdS = args[num];
			int ct = 0;
			int [] ids = uMgr.findId(pstuser, "Events='%" + evtIdS + "%'");
			for (int i=0; i<ids.length; i++)
			{
				PrmEvent.unstackEvent(pstuser, ids[i], evtIdS);
				ct++;
			}
			System.out.println("unstack evt [" + evtIdS + "] for " + ct + " users.");
		}


		////////////////////////////////////////////////////
	}

}
