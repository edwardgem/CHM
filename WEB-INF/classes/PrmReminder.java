//
///////////////////////////////////////////////////////////////////////////////////////////
//
//	File:		PrmReminder.java
//	Author:		ECC
//	Date:		10/07/2005
//	Description:
//			Send out notification email to action item coordinator based on the input date
//			and the deadline of the item.  Those item that has the entered date as deadline
//			this class will shoot a reminder message to the coordinator.
//
//	Modification:
//
///////////////////////////////////////////////////////////////////////////////////////////
//

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;

import oct.codegen.action;
import oct.codegen.actionManager;
import oct.codegen.meetingManager;
import oct.codegen.projectManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.pst.PstAbstractObject;
import oct.pst.PstGuest;
import oct.pst.PstUserAbstractObject;
import util.Util;

public class PrmReminder
{
	static final String ACTION_ALERT_SUBJ	= "[PRM Alert] Action Item ";
	static final String MAILFILE			= "alert.htm";
	static final String HOST				= Util.getPropKey("pst", "PRM_HOST");

	public static void main(String[] args)
		throws Exception
	{
		if (args.length < 1)
		{
			System.out.println("Usage: PrmReminder sends notification messsage to action item coordinator.");
			System.out.println("       Those items that have the deadline coincide with the entered date");
			System.out.println("       will be selected.");
			System.out.println("> java PrmReminder 10/7/2005");
			return;
		}

		boolean bNoSend = false;
		if (args.length >= 2 && args[1].equalsIgnoreCase("-nosend"))
			bNoSend = true;

		SimpleDateFormat df = new SimpleDateFormat("MM/dd/yyyy");
		SimpleDateFormat df2 = new SimpleDateFormat("yyyy.MM.dd.HH.mm.ss");
		Date deadline = df.parse(args[0]);
		Calendar cal = Calendar.getInstance();
		cal.setTime(deadline);

		int yr = cal.get(Calendar.YEAR);
		if (yr < 2000)
		{
			cal.set(Calendar.YEAR, 2000+yr);
			deadline = cal.getTime();
		}

		userManager uMgr = userManager.getInstance();
		actionManager aMgr = actionManager.getInstance();
		projectManager pjMgr = projectManager.getInstance();
		meetingManager mtgMgr = meetingManager.getInstance();

		// connect to PRM
		PstUserAbstractObject gUser = (PstUserAbstractObject) PstGuest.getInstance();
		String spec_uname = Util.getPropKey("pst", "PRIVILEGE_USER");
		String spec_passwd = Util.getPropKey("pst", "PRIVILEGE_PASSWD");
		user prmuser = (user)uMgr.login(gUser, spec_uname, spec_passwd);
		System.out.println("... connected");

		// for each action item that match the ExpireDate, send reminder email
		int [] actids = aMgr.findId(prmuser, "Type='" + action.TYPE_ACTION
			+ "' && Status='" + action.OPEN
			+ "' && ExpireDate='" + df2.format(deadline) + "'");
		action ai;
		for (int i=0; i<actids.length; i++)
		{
			// for every open action item
			ai = (action)aMgr.get(prmuser, actids[i]);
			System.out.print("found action [" + ai.getObjectId() +"]");

			// move the item to late
			ai.setAttribute("Status", action.LATE);
			aMgr.commit(ai);

			String s = null;
			PstAbstractObject o, u;
			if (!bNoSend)
			{
				String msg = "The following Action Item is now past due <blockquote>";
				String mid = (String)ai.getAttribute("MeetingID")[0];
				String from = null;
				if (mid == null)		// if mid is null, there must be a project id
					s = (String)ai.getAttribute("ProjectID")[0];
				msg += "<a href='" + HOST;
				if (mid != null)
				{
					msg += "/meeting/mtg_view.jsp?mid=" + mid + "&aid=" + actids[i] + "#action'>";
					o = mtgMgr.get(prmuser, mid);
				}
				else
				{
					msg += "/project/proj_action.jsp?projId=" + s + "&aid=" + actids[i] + "'>";
					o = pjMgr.get(prmuser, Integer.parseInt(s));
				}
				msg += (String)ai.getAttribute("Subject")[0] + "</a></blockquote>";

				u = uMgr.get(prmuser, Integer.parseInt((String)o.getAttribute("Owner")[0]));
				from = (String)u.getAttribute("Email")[0];

				String owner = (String)ai.getAttribute("Owner")[0];

				String subject = ACTION_ALERT_SUBJ + actids[i] + " is past due";

				System.out.println(" ... send notification");
				Util.createAlert(prmuser, subject, msg, 0, "Alert", 0, 0, owner);
				Util.sendMailAsyn(prmuser, from, owner, null, null, subject, msg, MAILFILE);
			}
			System.out.println("");
		}

		// logout
		uMgr.logout(prmuser);
		System.out.println("... close session");
	}

}
