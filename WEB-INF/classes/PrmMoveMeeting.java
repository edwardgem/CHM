import java.util.Calendar;
import java.util.Date;

import oct.codegen.actionManager;
import oct.codegen.meetingManager;
import oct.codegen.user;
import oct.omm.client.OmsMember;
import oct.omm.client.OmsOrganization;
import oct.omm.client.OmsSession;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstManager;

//
///////////////////////////////////////////////////////////////////////////////////////////
//
//	File:		PrmMoveMeeting.java
//	Author:		ECC
//	Date:		09/16/2011
//	Description:
//			For demo purpose, roll some meetings forward by Yr or Mo.
//
///////////////////////////////////////////////////////////////////////////////////////////
//

public class PrmMoveMeeting {
	private static final String exprMtg = 		//"om_acctname='%'";
		"(StartDate>'2005.01.01' && StartDate<'2010.4.1' && Type='Private' && TownID='29079')";
	private static final String [] mtgDateField =
				{"StartDate", "ExpireDate", "EffectiveDate", "CompleteDate", "LastUpdatedDate"};
	private static final String [] actDateField =
				{"CreatedDate", "ExpireDate", "CompleteDate"};
	
	private static meetingManager mMgr;
	private static actionManager actMgr;

	private static user u;		// source db user

	public static void main(String[] args)
		throws Exception
	{
		// connect to two separate databases as special user
		if (args.length < 2)
		{
			System.out.println("Usage 1: runtool PrmMoveMeeting SourcePool Yr Mo Dy\n");
			return;
		}
		
		int yr, mo, dy;
		yr = mo = dy = 0;
		
		yr = Integer.parseInt(args[1]);
		System.out.print("\nRoll OMM meeting from " + args[0] + " forward " + yr + "Yr ");
		
		if (args.length > 2) {
			mo = Integer.parseInt(args[2]);
			System.out.print(mo + "Mo ");
		}
		if (args.length > 3) {
			dy = Integer.parseInt(args[3]);
			System.out.print(dy + "Dy ");
		}
		System.out.println("\n-----------\n");
	
		// (source)
		OmsSession session = new OmsSession();
		System.out.println("Connecting to source: " + args[0]);
		session.connect(args[0], "user", "prmus3r", "john155");
		OmsOrganization org = new OmsOrganization(session, "user");
		OmsMember member = new OmsMember(session, org, "prmus3r");
		u = new user(member);
		
		// init
		mMgr = meetingManager.getInstance();
		actMgr = actionManager.getInstance();

		// get the selected meetings out and roll forward
		int aCount=0, mCount=0;
		int [] ids = mMgr.findId(u, exprMtg);
		int [] ids1;
		for (int i=0; i<ids.length; i++) {
			// roll meeting forward
			rollforward(mMgr, mMgr.get(u, ids[i]), yr, mo, dy);
			mCount++;
			
			// roll action forward
			ids1 = actMgr.findId(u, "MeetingID='" + ids[i]
			                          + "' && ExpireDate>='2005.10.15'");
			if (ids1.length <= 0) continue;

			// there is action item with this old meeting: migrate
			for (int j=0; j<ids1.length; j++) {
				rollforward(actMgr, actMgr.get(u, ids1[j]), yr, mo, dy);
				aCount++;
			}
		}
		
		// done
		System.out.println("Mtg    moved     = " + mCount);
		System.out.println("Action moved     = " + aCount);

	}

	/**
	 * roll the dates of an OMM object forward
	 * @param mMgr2
	 * @param pstAbstractObject
	 * @param yr
	 * @param mo
	 * @param dy
	 * @throws PmpException 
	 */
	private static void rollforward(
							PstManager mgr,
							PstAbstractObject obj,
							int yr, int mo, int dy)
		throws PmpException {
		// roll object forward by yr, mo, dy
		String type = null;
		String [] dateField = null;
		
		if (mgr instanceof meetingManager) {
			dateField = mtgDateField;
			type = "meeting";
		}
		else if (mgr instanceof actionManager) {
			dateField = actDateField;
			type = "action";
		}

		for (int i=0; i<dateField.length; i++) {
			rollForwardDate(obj, dateField[i], Calendar.YEAR, yr);
			rollForwardDate(obj, dateField[i], Calendar.MONTH, mo);
			rollForwardDate(obj, dateField[i], Calendar.DATE, dy);
		}
		mgr.commit(obj);
		System.out.println(type + " [" + obj.getObjectId() + "] rolled");
	}

	private static void rollForwardDate(PstAbstractObject obj, String attName, int dateType, int num)
		throws PmpException
	{
		if (num == 0) return;
		Date dt = (Date)obj.getAttribute(attName)[0];
		if (dt != null) {
			Calendar cal = Calendar.getInstance();
			cal.setTime(dt);
			cal.roll(dateType, num);
			obj.setAttribute(attName, cal.getTime());
		}
	}

}
