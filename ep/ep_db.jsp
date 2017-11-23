<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<%@page import="java.text.ParseException"%><html>
<%
//
//	Copyright (c) 2010, EGI Technologies  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: ep_db.jsp
//	Author: ECC
//	Date:	08/11/10
//	Description: Dashboard.
//
/////////////////////////////////////////////////////////////////////
//

%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "mod.mfchat.OmfEventAjax" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.SimpleDateFormat" %>

<%!
	// static classes and methods
	static final String TABLE0 = "<table width='100%' border='0' cellspacing='0' cellpadding='0'>";
	static final SimpleDateFormat df0 = new SimpleDateFormat ("MM/dd/yy");
	static final SimpleDateFormat df1 = new SimpleDateFormat ("yyyy.MM.dd.hh.mm");
	static final SimpleDateFormat df3 = new SimpleDateFormat ("MM/dd/yyyy hh:mm a");
	static final SimpleDateFormat df4 = new SimpleDateFormat ("MM dd yyyy hh mm");
	static final String LIGHT	= Prm.LIGHT;
	static final String DARK	= Prm.DARK;
	static final String PUBLIC_IND = "<span style='color:#00bb00; font-size:13px; font-weight:bold;'> *</span>";

	String createDashBoardTable(String title, String content, int height,
				String titleBgColor, String titleColor)
	{
		StringBuffer sBuf = new StringBuffer(4096);
		if (content==null || content=="") {
			content = "<span class='plaintext_grey'>None</span>";
		}

		String borderColor = "#999999";
		if (titleBgColor == null) {
			titleBgColor = "#99aacc";
		}
		if (titleColor == null) {
			titleColor = "#ffffff";
		}

		String heightS;
		if (height < 0) {
			heightS = Math.abs(height) + "%";
		}
		else {
			heightS = String.valueOf(height);
		}

		// overall table
		sBuf.append("<table border='0' cellspacing='0' cellpadding='0' ");
		sBuf.append("width='100%' ");	// always 100% because caller use TD to control width
		if (height != 0) sBuf.append("height='" + heightS + "'");
		sBuf.append(">");

		// top rounded edge table with title line
		sBuf.append("<tr bgcolor='" + titleBgColor + "'><td>");
		sBuf.append(TABLE0);
		sBuf.append("<tr><td id='tl'></td>");
		sBuf.append("<td class='subhead' style='line-height:20px; border:0px;");
		if (titleColor != null)
			sBuf.append("color:" + titleColor + ";");
		sBuf.append("'>");
		sBuf.append(title);
		sBuf.append("</td><td id='tr'></td><tr></table>");
		sBuf.append("</td></tr>");

		// content table
		sBuf.append("<tr><td>");
		sBuf.append("<table class='panel' width='100%' cellspacing='0' cellpadding='0'>");
		sBuf.append("<tr><td style='padding:5px 5px 0 5px;'>");
		sBuf.append(content);
		sBuf.append("</td></tr>");
		sBuf.append("</table>");
		sBuf.append("</td></tr>");

		// bottom rounded edge table
		sBuf.append("<tr><td>");
		sBuf.append(TABLE0);
		sBuf.append("<tr><td><img src='../i/cornerBL.gif'/></td>");
		sBuf.append("<td width='100%'><table class='botTD' border='0' cellspacing='0' cdellpadding='0'>"
				+ "<tr><td></td></tr></table></td>");
		sBuf.append("<td><img src='../i/cornerBR.gif'/></td></tr>");
		sBuf.append("</table>");
		sBuf.append("</td></tr>");

		// close overall table
		sBuf.append("</table>");

		return sBuf.toString();
	}


	String getProjectList(PstUserAbstractObject u)
		throws PmpException
	{
		StringBuffer sBuf = new StringBuffer(4096);
		projectManager pjMgr = projectManager.getInstance();
		userManager uMgr = userManager.getInstance();
		PstAbstractObject uObj;

		int [] ids = pjMgr.getProjects(u, false);	// false: no close projects
		if (ids.length > 0) {
			String [] label = {"St", "&nbsp;Name", "Coordinator", "Due Date"};
			int [] labelLen = {-5, -55, -20, -20};
			boolean [] bAlignCenter = {true, false, true, true};
			// showAll and align center, with label bgcolor
			sBuf.append(Util.showLabel(label, null, null, null,
					labelLen, bAlignCenter, true, "#c0c0c0"));

			PstAbstractObject [] pjObjList = pjMgr.get(u, ids);
			Util.sortName(pjObjList, true);
			boolean even = false;
			
			String myUidS = String.valueOf(u.getObjectId());

			int iSize;
			String dot, bgcolor;
			Date dt;
			String expDateS = null;
			String doneDateS = null;

			for (int i=0; i < pjObjList.length; i++) {
				// project
				project pjObj = (project) pjObjList[i];
				String projName = pjObj.getDisplayName();
				int projId = pjObj.getObjectId();
				
				// filter personal space (for PM)
				String owner = (String)pjObj.getAttribute("Owner")[0];
				if (!myUidS.equals(owner)
					&& (pjObj.getObjectName().contains("Personal Space@@")) ) {
						continue;	// filter other's personal space
				}

				// status
				String color;
				String status = (String)pjObj.getAttribute("Status")[0];
				if (status == null) {
					status = "";
				}

				// get owner's name
				String name = "-";
				try {
					if(owner != null) {
						uObj = uMgr.get(u, Integer.parseInt(owner));
						name = ((user)uObj).getShortName();
					}
				}
				catch (PmpException e) {
					System.out.println("Cannot find project owner [" + owner + "]");
				}

				// dates
				dt = pjObj.getExpireDate();
				if (dt != null) expDateS = df0.format(dt);
				else expDateS = "-";
				
				dt = pjObj.getCompleteDate();
				if (dt != null) doneDateS = df0.format(dt);
				else doneDateS = null;

				if (even)
					bgcolor = DARK;
				else
					bgcolor = LIGHT;
				even = !even;


				/////////////////////////////////////////////////////////
				// ready to display
				sBuf.append("<tr " + bgcolor + ">");

				// status
				sBuf.append("<td height='30'></td>");
				sBuf.append("<td width='30' class='plaintext' " + bgcolor + " align='center'>");
				sBuf.append(pjObj.getStatusDisplay(u, false));
				sBuf.append("</td>");

				// project name
				sBuf.append("<td><img src='../i/spacer.gif' width='2'/></td><td></td>");
				sBuf.append("<td class='ptextS2'><a href='../project/proj_top.jsp?projId=");
				sBuf.append(projId + "'>" + projName + "</a></td>");

				// project owner
				sBuf.append("<td colspan='2'></td>");
				sBuf.append("<td class='plaintext' align='center'>");
				sBuf.append("<a href='../ep/ep1.jsp?uid=" + owner + "'>" + name + "</a></td>");

				// deadline
				sBuf.append("<td colspan='2'></td>");
				sBuf.append("<td class='plaintext' align='center'>");
				sBuf.append(expDateS);
				sBuf.append("</td>");

				sBuf.append("</tr>");

			}	// END: for each project
		}
		else {
			sBuf.append("<table><tr><td><img src='../i/bullet_tri.gif'/></td>");
			sBuf.append("<td class='plaintext_big'><a href='../project/proj_new1.jsp'>Click to add a new project</a></td>");
		}

		sBuf.append("</table>");	// close the label table
		return sBuf.toString();
	}	// END: getProjectList()


	// return the total number of defects for the company
	String getOpenActionNum(PstUserAbstractObject u)
		throws PmpException
	{
		StringBuffer sBuf = new StringBuffer(128);
		String companyIdS = u.getStringAttribute("Company");
		if (companyIdS == null)
			companyIdS = (String)u.getAttribute("TownID")[0];
		/* for bug number
		bugManager bMgr = bugManager.getInstance();
		int [] ids = bMgr.findId(u, "Company='" + companyIdS + "'");
		*/
		actionManager aMgr = actionManager.getInstance();
		int [] ids = aMgr.findId(u, "Company='" + companyIdS + "'");

		sBuf.append("<table width='100%'><tr><td align='center' class='bugNum'>");
		sBuf.append(ids.length);
		sBuf.append("</td></tr></table>");

		return sBuf.toString();
	}	// END: getOpenActionNum()


	String getMeetingList(PstUserAbstractObject u)
		throws PmpException, ParseException
	{
		StringBuffer sBuf = new StringBuffer(4096);
		meetingManager mtgMgr = meetingManager.getInstance();
		String myUidS = String.valueOf(u.getObjectId());

		// collect all my belonging towns
		// ECC: would this work for enterprise?  Do we store my company in Towns?
		String townString = Util2.getAttributeString(u, "Towns", ";");

		Calendar ca = Calendar.getInstance();
		Date now = ca.getTime();
		now = new Date(now.getTime());
		String [] sa = df4.format(now).split(" ");
		sa[3] = "00";
		sa[4] = "00";
		String s = "";
		for (int i = 0; i<sa.length; i++)
		{
			s = s.concat(sa[i]);
			s = s.concat(" ");
		}
		now = df4.parse(s);
		now = new Date(now.getTime() + 7*3600000);

		long temp = now.getTime();
		Long day = new Long(86400000);
		long temp2 = day.longValue();
		temp = temp + temp2;
		Date tomorrow = new Date(temp);

		temp = temp + temp2;
		Date nextD = new Date(temp);

		String expr = "(StartDate>='" + df1.format(now)+ "') && (StartDate<'" + df1.format(tomorrow) + "')";
		int [] mIds1 = mtgMgr.findId(u, expr);
		int count = 0;
		PstAbstractObject [] mtgArr = mtgMgr.get(u, mIds1);
		int len = mtgArr.length;
		if (len > 1)
			Util.sortDate(mtgArr, "StartDate");

		boolean found;
		PstAbstractObject m;
		for (int i=0; i<mtgArr.length; i++)
		{
			found = false;
			m = mtgArr[i];

			if (m.getAttribute("Type")[0].equals(meeting.PUBLIC))
				{count++; continue;}		// include public meeting

			if (myUidS.equals(m.getAttribute("Owner")))
				{count++; continue;}		// found

			s = (String)m.getAttribute("TownID")[0];
			if (s!=null && townString.indexOf(s)!=-1)
				{count++; continue;}		// found same town

			Object [] oArr = m.getAttribute("Attendee");
			for (int j=0; j<oArr.length; j++)
			{
				s = (String)oArr[j];
				if (s == null) break;		// no attendee
				if (s.startsWith(myUidS))
				{
					found = true;
					count++;
					break;					// found
				}
			}
			if (!found)
				mtgArr[i] = null;			// don't show this meeting
		}

		sBuf.append("<table border='0' cellspacing='0' cellpadding='0'>");
		sBuf.append("<tr><td class='plaintext_blue' colspan='4'>Today</td></tr>");
		sBuf.append("<tr><td height='3'><img src='../i/spacer.gif' width='1' height='3'/></td></tr>");

		String typeInd, start, end, subj;
		String mtgState = null;
		Date startD, endD;
		int id;
		if (count != 0)
		{
			for (int i=0; i<mtgArr.length; i++)
			{
				m = mtgArr[i];
				if (m != null)
				{
					startD = (Date)m.getAttribute("StartDate")[0];
					start = df3.format(startD);
					endD = (Date)m.getAttribute("ExpireDate")[0];
					end = df3.format(endD);
					id = m.getObjectId();
					subj = (String)m.getAttribute("Subject")[0];
					if (m.getAttribute("Type")[0].equals(meeting.PUBLIC))
						typeInd = PUBLIC_IND;
					else
						typeInd = "";
					mtgState = (String)m.getAttribute("Status")[0];
					sBuf.append("<tr><td width='2'>&nbsp;</td>");
					sBuf.append("<td class='plaintext' valign='top' colspan='3'>");

					// store the javascript to be executed by caller???
					sBuf.append("<script language='JavaScript'>");
					sBuf.append("var stD = new Date('" + start + "');");
					sBuf.append("var enD = new Date('" + end + "');");

					sBuf.append("var tm = stD.getTime() + diff;");
					sBuf.append("stD = new Date(tm);");

					sBuf.append("tm = enD.getTime() + diff;");
					sBuf.append("enD = new Date(tm);");
					//sBuf.append("document.write(formatDate(stD, 'hh:mm') + ' - ' + formatDate(enD, 'hh:mm a'));");
					sBuf.append("document.write(formatDate(stD, 'M/dd (E) hh:mm') + ' - ' + formatDate(enD, 'hh:mm a'));");
					sBuf.append("</script>");


					sBuf.append("</td></tr>");
					sBuf.append("<tr><td width='5'></td>");
					sBuf.append("<td><img src='../i/spacer.gif' width='10'></td>");
					sBuf.append("<script language='JavaScript'>showStatus('"
							+ mtgState + "');</script>");
					sBuf.append("<td width='240' valign='middle'><a class='listlink' href='../meeting/mtg_view.jsp?mid="
							+ id + "'>" + subj + "</a>" + typeInd + "</td></tr>");
					sBuf.append("<tr><td colspan='4'><img src='../i/spacer.gif' width='1' height='5' border='0'></td></tr>");
				}
			}
		}
		else
		{
			sBuf.append("<tr><td><img src='../i/spacer.gif' width='5' height='2'></td>");
			sBuf.append("<td class='plaintext_grey' valign='top' colspan='3'>&nbsp;None</td></tr>");
		}

		////////////////////////
		// tomorrow
		sBuf.append("<tr><td height='5' colspan='4'><img src='../i/spacer.gif' width='1' height='5' border='0'></td></tr>");
		sBuf.append("<tr><td class='plaintext_blue' colspan='4'>Tomorrow</td></tr>");
		sBuf.append("<tr><td height='3' colspan='4'><img src='../i/spacer.gif' width='1' height='3' border='0'></td></tr>");

		expr = "(StartDate>='" + df1.format(tomorrow)+ "') && (StartDate<'" + df1.format(nextD) + "')";
		int [] mIds2 = mtgMgr.findId(u, expr);
		count = 0;

		mtgArr = mtgMgr.get(u, mIds2);
		len = mtgArr.length;
		if (len > 1)
			Util.sortDate(mtgArr, "StartDate");

		for (int i=0; i<mtgArr.length; i++) {
			found = false;
			m = mtgArr[i];

			if (m.getAttribute("Type")[0].equals(meeting.PUBLIC))
				{count++; continue;}		// include public meeting

			if (myUidS.equals(m.getAttribute("Owner")))
				{count++; continue;}		// found

			s = (String)m.getAttribute("TownID")[0];
			if (s!=null && townString.indexOf(s)!=-1)
				{count++; continue;}		// found same town

			Object [] oArr = m.getAttribute("Attendee");
			for (int j=0; j<oArr.length; j++) {
				s = (String)oArr[j];
				if (s == null) break;		// no attendee
				if (s.startsWith(myUidS))
				{
					found = true;
					count++;
					break;					// found
				}
			}
			if (!found)
				mtgArr[i] = null;			// don't show this meeting
		}

		if (count != 0) {
			for (int i=0; i<mtgArr.length; i++) {
				m = mtgArr[i];
				if (m != null) {
					startD = (Date)m.getAttribute("StartDate")[0];
					start = df3.format(startD);
					endD = (Date)m.getAttribute("ExpireDate")[0];
					end = df3.format(endD);
					id = m.getObjectId();
					subj = (String)m.getAttribute("Subject")[0];
					mtgState = (String)m.getAttribute("Status")[0];
					if (m.getAttribute("Type")[0].equals(meeting.PUBLIC))
						typeInd = PUBLIC_IND;
					else
						typeInd = "";
					sBuf.append("<tr><td width='2'>&nbsp;</td>");

					sBuf.append("<td class='plaintext' valign='top' colspan='3'>");
					sBuf.append("<script language='JavaScript'>");
					sBuf.append("var stD = new Date('" + start + "');");
					sBuf.append("var enD = new Date('" + end + "');");

					sBuf.append("var tm = stD.getTime() + diff;");
					sBuf.append("stD = new Date(tm);");

					sBuf.append("tm = enD.getTime() + diff;");
					sBuf.append("enD = new Date(tm);");
					sBuf.append("document.write(formatDate(stD, 'hh:mm') + ' - ' + formatDate(enD, 'hh:mm a'));");
					sBuf.append("</script>");
					sBuf.append("</td>");

					sBuf.append("</tr>");
					sBuf.append("<tr><td width='5'></td>");
					sBuf.append("<td><img src='../i/spacer.gif' width='10'></td>");
					sBuf.append("<script language='JavaScript'>showStatus('" + mtgState
							+ "');</script>");
					sBuf.append("<td width='240' valign='middle'><a class='listlink' href='../meeting/mtg_view.jsp?mid="
							+ id + "'>" + subj + "</a>" + typeInd + "</td></tr>");
					sBuf.append("<tr><td colspan='4'><img src='../i/spacer.gif' width='1' height='5' border='0'></td></tr>");
				}
			}
		}
		else
		{
			sBuf.append("<tr><td><img src='../i/spacer.gif' width='5' height='2' border='0'></td>");
			sBuf.append("<td class='plaintext_grey' valign='top' colspan='3'>&nbsp;None</td></tr>");
		}


		////////////////////////////////////////
		// other days of the week
		sBuf.append("<tr><td colspan=4><img src='../i/spacer.gif' width='1' height='5' border='0'/></td></tr>");
		sBuf.append("<tr><td class='plaintext_blue' colspan=4>Other Days of the Week</td></tr>");
		sBuf.append("<tr><td colspan='4'><img src='../i/spacer.gif' width='1' height='3' border='0'/></td></tr>");

		GregorianCalendar thisSat = new GregorianCalendar();
		GregorianCalendar lastSun = new GregorianCalendar();
		thisSat.setTime(now);
		lastSun.setTime(now);
		while (thisSat.get(Calendar.DAY_OF_WEEK) != Calendar.SATURDAY) {
			thisSat.add(Calendar.DATE, 1);
		}
		while (lastSun.get(Calendar.DAY_OF_WEEK) != Calendar.SUNDAY) {
			lastSun.add(Calendar.DATE, -1);
		}

		Date lastSunD = lastSun.getTime();
		Date thisSatD = thisSat.getTime();
		temp = thisSatD.getTime();
		temp = temp + temp2;
		thisSatD = new Date(temp);

		expr = "(StartDate>='" + df1.format(lastSunD)+ "') && (StartDate<'" + df1.format(thisSatD) + "')";

		int [] mIds = mtgMgr.findId(u, expr);

		// take out all those that appear in the first two int arrays mIds1 and mIds2
		int ct = 0;
		for (int i=0; i<mIds.length; i++) {
			if (mIds[i] > 0) {
				found = false;
				for (int j=0; j<mIds1.length; j++)
					if (mIds[i] == mIds1[j]) {mIds[i]=-1; found=true; ct++; break;}
				if (!found)
					for (int j=0; j<mIds2.length; j++)
						if (mIds[i] == mIds2[j]) {mIds[i]=-1; ct++; break;}
			}
		}
		// now re-construct the rest of the week mId array
		int idx = 0;
		if (ct > 0) {
			mIds1 = new int[mIds.length - ct];
			for (int i=0; i<mIds.length; i++)
				if (mIds[i] > 0) mIds1[idx++] = mIds[i];
		}
		else
			mIds1 = mIds;

		mtgArr = mtgMgr.get(u, mIds1);
		len = mtgArr.length;
		if (len > 1)
			Util.sortDate(mtgArr, "StartDate");

		for (int i=0; i<mtgArr.length; i++) {
			m = mtgArr[i];

			if (m.getAttribute("Type")[0].equals(meeting.PUBLIC))
				continue;					// include public meeting

			if (myUidS.equals(m.getAttribute("Owner")))
				continue;					// found

			s = (String)m.getAttribute("TownID")[0];
			if (s!=null && townString.indexOf(s)!=-1)
				{count++; continue;}		// found same town

			found = false;
			Object [] oArr = m.getAttribute("Attendee");
			for (int j=0; j<oArr.length; j++) {
				s = (String)oArr[j];
				if (s == null) break;		// no attendee
				if (s.startsWith(myUidS)) {
					found = true;
					break;					// found
				}
			}
			if (!found)
				mtgArr[i] = null;			// don't show this meeting
		}

		count = 0;
		for (int i=0; i<mtgArr.length; i++) {
			m = mtgArr[i];
			if (m != null) {
				mtgState = (String)m.getAttribute("Status")[0];
				if (mtgState.equals(meeting.EXPIRE))
					continue;
				count++;
				startD = (Date)m.getAttribute("StartDate")[0];
				start = df3.format(startD);
				endD = (Date)m.getAttribute("ExpireDate")[0];
				end = df3.format(endD);
				id = m.getObjectId();
				subj = (String)m.getAttribute("Subject")[0];
				if (m.getAttribute("Type")[0].equals(meeting.PUBLIC))
					typeInd = PUBLIC_IND;
				else
					typeInd = "";
				sBuf.append("<tr><td width='2'>&nbsp;</td>");

				sBuf.append("<td class='blog_text' valign='top' colspan='3'>");
				sBuf.append("<script language='JavaScript'>");
				sBuf.append("var stD = new Date('" + start + "');");
				sBuf.append("var enD = new Date('" + end + "');");
				sBuf.append("var tm = stD.getTime() + diff;");
				sBuf.append("stD = new Date(tm);");
				sBuf.append("tm = enD.getTime() + diff;");
				sBuf.append("enD = new Date(tm);");
				sBuf.append("document.write(formatDate(stD, 'M/dd (E) hh:mm') + ' - ' + formatDate(enD, 'hh:mm a'));");
				sBuf.append("</script>");
				sBuf.append("</td>");

				sBuf.append("</tr>");
				sBuf.append("<tr><td width='5'></td>");
				sBuf.append("<td><img src='../i/spacer.gif' width='10'></td>");
				sBuf.append("<script language='JavaScript'>showStatus('" + mtgState + "');</script>");
				sBuf.append("<td width='240' valign='middle'><a class='listlink' href='../meeting/mtg_view.jsp?mid=" + id + "'>" + subj + "</a>" + typeInd + "</td></tr>");
				sBuf.append("<tr><td colspan='4'><img src='../i/spacer.gif' width='1' height='5' border='0'></td></tr>");
			}
		}

		if (count <= 0) {
			sBuf.append("<tr><td><img src='../i/spacer.gif' width='5' height='2'></td>");
			sBuf.append("<td class='plaintext_grey' valign='top' colspan='3'>&nbsp;None</td></tr>");
		}


		/////////////////////////////
		// upcoming
		//
		sBuf.append("<tr><td height='5' colspan=4><img src='../i/spacer.gif' width='1' height='5' border='0'></td></tr>");
		sBuf.append("<tr><td class='plaintext_blue' colspan=4>Upcoming ...</td></tr>");
		sBuf.append("<tr><td colspan='4'><img src='../i/spacer.gif' width='1' height='3' border='0'></td></tr>");

		GregorianCalendar future = (GregorianCalendar)thisSat.clone();
		future.add(Calendar.MONTH, 1);
		expr = "(StartDate>'" + df1.format(thisSatD) + "') && (StartDate<'" + df1.format(future.getTime()) + "')";
		mIds = mtgMgr.findId(u, expr);

		// take out all those that appear in the tomorrow array mIds2
		ct = 0;
		for (int i=0; i<mIds.length; i++)
		{	if (mIds[i] > 0)
			{
				for (int j=0; j<mIds2.length; j++)
					if (mIds[i] == mIds2[j]) {mIds[i]=-1; ct++; break;}
			}
		}
		// now re-construct the upcoming mId array
		idx = 0;
		if (ct > 0)
		{
			mIds1 = new int[mIds.length - ct];
			for (int i=0; i<mIds.length; i++)
				if (mIds[i] > 0) mIds1[idx++] = mIds[i];
		}
		else
			mIds1 = mIds;


		mtgArr = mtgMgr.get(u, mIds1);
		len = mtgArr.length;
		if (len > 1)
			Util.sortDate(mtgArr, "StartDate");

		for (int i=0; i<mtgArr.length; i++)
		{
			found = false;
			m = mtgArr[i];

			if (m.getAttribute("Type")[0].equals(meeting.PUBLIC))
				continue;					// include public meeting

			if (myUidS.equals(m.getAttribute("Owner")))
				continue;					// found

			s = (String)m.getAttribute("TownID")[0];
			if (s!=null && townString.indexOf(s)!=-1)
				{count++; continue;}		// found same town

			Object [] oArr = m.getAttribute("Attendee");
			for (int j=0; j<oArr.length; j++)
			{
				s = (String)oArr[j];
				if (s == null) break;		// no attendee
				if (s.startsWith(myUidS))
				{
					found = true;
					break;					// found
				}
			}
			if (!found)
				mtgArr[i] = null;			// don't show this meeting
		}

		count = 0;
		for (int i=0; i<mtgArr.length; i++) {
			m = mtgArr[i];
			if (m != null) {
				mtgState = (String)m.getAttribute("Status")[0];
				if (mtgState.equals(meeting.EXPIRE))
					continue;
				count++;
				startD = (Date)m.getAttribute("StartDate")[0];
				start = df3.format(startD);
				endD = (Date)m.getAttribute("ExpireDate")[0];
				end = df3.format(endD);
				id = m.getObjectId();
				subj = (String)m.getAttribute("Subject")[0];
				if (m.getAttribute("Type")[0].equals(meeting.PUBLIC))
					typeInd = PUBLIC_IND;
				else
					typeInd = "";
				sBuf.append("<tr><td width='2'>&nbsp;</td>");

				sBuf.append("<td class='blog_text' valign='top' colspan='3'>");
				sBuf.append("<script language='JavaScript'>");
				sBuf.append("var stD = new Date('" + start + "');");
				sBuf.append("var enD = new Date('" + end + "');");
				sBuf.append("var tm = stD.getTime() + diff;");
				sBuf.append("stD = new Date(tm);");
				sBuf.append("tm = enD.getTime() + diff;");
				sBuf.append("enD = new Date(tm);");
				sBuf.append("document.write(formatDate(stD, 'M/dd (E) hh:mm') + ' - ' + formatDate(enD, 'hh:mm a'));");
				sBuf.append("</script>");
				sBuf.append("</td>");

				sBuf.append("</tr>");
				sBuf.append("<tr><td width='5'></td>");
				sBuf.append("<td><img src='../i/spacer.gif' width='10'></td>");
				sBuf.append("<script language='JavaScript'>showStatus('" + mtgState + "');</script>");
				sBuf.append("<td width='240' valign='middle'><a class='listlink' href='../meeting/mtg_view.jsp?mid="
					+ id + "'>" + subj + "</a>" + typeInd + "</td></tr>");
				sBuf.append("<tr><td colspan='4'><img src='../i/spacer.gif' width='1' height='5' border='0'></td></tr>");
			}
		}

		if (count <= 0) {
			sBuf.append("<tr><td><img src='../i/spacer.gif' width='5' height='2'></td>");
			sBuf.append("<td class='plaintext_grey' valign='top' colspan='3'>&nbsp;None</td></tr>");
		}

		sBuf.append("<tr><td colspan='4' class='tinytype' ><img src='../i/spacer.gif' width='1' height='20' /><span style='color:#00bb00;'>* = Public meeting</span></td></tr>");

		// closing
		sBuf.append("</table>");
		return sBuf.toString();
	}	// END: getMeetingList()


	String getWatchList(PstUserAbstractObject u, Date lastLogin)
		throws PmpException
	{
		StringBuffer sBuf = new StringBuffer(4096);
		projectManager pjMgr = projectManager.getInstance();
		userManager uMgr = userManager.getInstance();
		taskManager tkMgr = taskManager.getInstance();
		latest_resultManager lrMgr = latest_resultManager.getInstance();

		latest_result lresultObj = null;
		task tk;
		planTask ptk;
		PstAbstractObject uObj;
		String projName, pidS, stackName, color, status, dot;
		String owner, name, blogText, bgcolor, latestBlog;
		int idx, len;
		boolean bBold;
		boolean even = false;
		Date lastUpdatedDate, lastBlogDate;

		int [] ids = tkMgr.findId(u, "Watch='" + u.getObjectId() + "'");
		int [] ids1;

		if (ids.length > 0) {
			String [] label = {"St", "&nbsp;Project / Task", "Owner", "&nbsp;Blog"};
			int [] labelLen = {-5, -35, -12, -48};
			boolean [] bAlignCenter = {true, false, true, false};
			// showAll and align center, with label bgcolor
			sBuf.append(Util.showLabel(label, null, null, null,
					labelLen, bAlignCenter, true, "#c0c0c0"));

			for (int i=0; i<ids.length; i++) {
				tk = (task)tkMgr.get(u, ids[i]);
				pidS = (String)tk.getAttribute("ProjectID")[0];
				projName = ((project)pjMgr.get(u, Integer.parseInt(pidS))).getDisplayName();
				ptk = tk.getPlanTask(u);
				stackName = TaskInfo.getTaskStack(u, ptk);
				idx = stackName.lastIndexOf(">>");
				if (idx > 0)
					stackName = stackName.substring(0, idx+2) + "<b>" + stackName.substring(idx+2) + "</b>";
				else
					stackName = "<b>" + stackName + "</b>";
				stackName = projName + " >> " + stackName;


				// status
				status = (String)tk.getAttribute("Status")[0];
				if (status == null) {
					status = "";
				}

				// get owner's first name
				name = "";
				owner = (String)tk.getAttribute("Owner")[0];
				if(owner != null) {
					uObj = uMgr.get(u, Integer.parseInt(owner));
					if(uObj.getAttribute("FirstName")[0] != null)
						name = (String)uObj.getAttribute("FirstName")[0];
					if(uObj.getAttribute("LastName")[0] != null)
						name += " " + ((String)uObj.getAttribute("LastName")[0]).substring(0,1).toUpperCase();
				}

				if (even)
					bgcolor = DARK;
				else
					bgcolor = LIGHT;
				even = !even;

				/////////////////////////////////////////////////////////
				// ready to display
				sBuf.append("<tr " + bgcolor + ">");

				// status
				sBuf.append("<td height='50'></td>");
				dot = "../i/";
				if (status.equals("Open")) {dot += "dot_lightblue.gif";}
				else if (status.equals("New")) {dot += "dot_orange.gif";}
				else if (status.equals("Completed")) {dot += "dot_green.gif";}
				else if (status.equals("On-hold")) {dot += "dot_grey.gif";}
				else if (status.equals("Canceled")) {dot += "dot_cancel.gif";}
				else if (status.equals("Late")) {dot += "dot_red.gif";}
				else {dot += "dot_grey.gif";}

				sBuf.append("<td width='30' class='plaintext' " + bgcolor + " align='center'>");
				sBuf.append("<img src='" + dot + "' title='" + status + "'>");
				sBuf.append("</td>");

				// project/task name
				sBuf.append("<td><img src='../i/spacer.gif' width='2'/></td><td></td>");
				sBuf.append("<td class='ptextS1'><a href='../project/task_update.jsp?projId=");
				sBuf.append(pidS + "&taskId=" + ids[i] + "'>" + stackName + "</a></td>");

				// task owner
				sBuf.append("<td colspan='2'></td>");
				sBuf.append("<td class='plaintext' align='center'>");
				sBuf.append("<a href='../ep/ep1.jsp?uid=" + owner + "'>" + name + "</a></td>");

				// blog

				// last updated date
				latestBlog = null;
				lastBlogDate = null;
				ids1 = lrMgr.findId(u, "get_latest_result", tk);
				if (ids1.length > 0)
				{
					lresultObj = (latest_result)lrMgr.get(u, ids1[0]);
					latestBlog = (String)lresultObj.getAttribute("LastComment")[0];
					lastBlogDate = (Date)lresultObj.getAttribute("LastUpdatedDate")[0];
				}

				sBuf.append("<td colspan='2'></td>");
				sBuf.append("<td class='plaintext' align='left'>");
				sBuf.append("<a class='listlink'  href='../blog/blog_task.jsp?projId="+pidS + "&planTaskId=" + ptk.getObjectId() + "'>");
				bBold = (lastBlogDate!=null && lastBlogDate.after(lastLogin))?true:false;
				if (latestBlog != null)
				{
					len = 90;
					if (bBold) {
						sBuf.append("<b>");
					}
					latestBlog = latestBlog.replaceAll("<\\S[^>]*>", "");		// strip HTML tag
					if (latestBlog.length()>len)
						latestBlog = latestBlog.substring(0,len);
					idx = latestBlog.indexOf("::");
					if (idx != -1) {
						sBuf.append("<font color='#0000ff'>" + latestBlog.substring(0,idx));
						sBuf.append("</font>" + latestBlog.substring(idx+1,latestBlog.length()) + " ...");
					}
					else
						sBuf.append(latestBlog + " ...");
					if (bBold) sBuf.append("</b>");
				}
				else
				{
					sBuf.append("no blog");
				}
				sBuf.append("</a>");
				sBuf.append("</td>");

				sBuf.append("</tr>");
			}
		}
		else {
			sBuf.append("<table><tr><td class='plaintext'>None</td></tr>");
		}

		sBuf.append("</table>");	// close the label table
		return sBuf.toString();
	}

%>

<%
	String noSession = "../out.jsp?go=ep/ep_db.jsp";
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../index.jsp");
		return;
	}
	String s = request.getParameter("full");
	boolean isPDA = Prm.isPDA(request);
	if (s==null && isPDA) {
		response.sendRedirect("ep_prm_pda.jsp");
		return;
	}

	boolean isCwModule = Prm.isCwModule(session);
	String appS = Prm.getAppTitle();

	userManager uMgr = userManager.getInstance();

	String myUidS = request.getParameter("uid");
	int uidInt = 0;

	int iRole = ((Integer)session.getAttribute("role")).intValue();

	if (StringUtil.isNullOrEmptyString(myUidS))
		myUidS = String.valueOf(pstuser.getObjectId());
	uidInt = Integer.parseInt(myUidS);

	user detailUser = (user)uMgr.get(pstuser, uidInt);

	String Title = (String)detailUser.getAttribute("Title")[0];
	String fName = (String)detailUser.getAttribute("FirstName")[0];
	String myFullName = detailUser.getFullName();

	Date lastLogin = (Date)session.getAttribute("lastLogin");

%>


<head>
<title><%=appS%> Dashboard</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta name="description" content="CPM is a social collaborative site for the enterprise" />
<meta name="keywords" content="social networking, chat, meeting" />
<script language="JavaScript" src="../get-date.js"></script>
<script language="JavaScript" src="../date.js"></script>
<script type="text/javascript" src="../meeting/ajax_utils.js"></script>
<script language="JavaScript" src="../meeting/mtg_expr.js"></script>
<script language="JavaScript" src="event.js"></script>
<script language="JavaScript" src="chat.js"></script>
<script src="201a.js" type="text/javascript"></script>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen">
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print">
<jsp:include page="../init.jsp" flush="true"/>
<jsp:include page="../errormsg.jsp" flush="true"/>
<script language="JavaScript">
<!--

// the followings are declared in event.js
var uid = "<%=myUidS%>";
var current_eid = -1;		// last received event Id
var act_hello = "<%=PrmEvent.ACT_HELLO%>";		// action() in event.js needs this
var diff = getDiffUTC();
var bDisplaySearch = false;
frame = "parent";			// define in event.js
myName = "<%=myFullName%>";

window.onload = function()
{
	ajax_init();
}

function resetAction()
{
	if (showingId != "")
	{
		var e = document.getElementById(showingId);
		if (e != null)
		{
			e.style.display = "none";
			e.innerHTML = "";
		}

		// make sure if a reply button (on posted note or join chat) has been hidden, make it seen now
		if (showingId.indexOf("-") != -1) {
			e = document.getElementById("reply-" + showingId);
			if (e == null)
				e = document.getElementById("chatReply-" + showingId);
			if (e != null) e.style.display = "block";
		}

		showingId = "";
	}
	rename_chat(null, 1);		// remove the rename chat box on screen
}

function showStatus(st)
{
	var fn;
	var s;
	if (st=='Live') {fn = 'dot_red.gif'; s = 'On Air';}
	else if (st=='New') {fn = 'dot_green.gif'; s = 'New';}
	else if (st=='Finish') {fn = 'dot_blue.gif'; s = 'Finished'}
	else {fn = 'dot_black.gif'; s = 'Closed/Canceled';}
	document.write("<td valign='baseline' title='" + s + "'><img src='../i/" + fn + "' border='0'></td>");
}

//-->
</script>

<%
	response.setHeader("Pragma", "No-Cache");
	response.setDateHeader("Expires", 0);
	response.setHeader("Cache-Control", "no-Cache");
%>

</head>

<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<bgsound id="IESound">
<span id="FFSound"></span>

<style type="text/css">
<% if (isPDA) {%>
.plaintext {font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 32px; color: #333333; line-height: 34px}
.plaintext_small {  font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 34px; font-weight:normal;color: #999999; line-height: 36px; padding-bottom:5px;}
.plaintext_grey {  font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 36px; color: #777777; line-height: 34px}
.plaintext_blue {  font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 32px; font-weight: bold; color: #336699; line-height: 36px}
.listlink { font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 34px; color: #3366aa; line-height: 32px; text-decoration: underline}
.bq_note { border:1px solid #ddd; margin: 5px; margin-right:12px; padding: 5px; padding-top:3px; background: #ffffbb; text-wrap:normal;word-wrap:break-word }
.comment {font-family: Verdana, Arial, Helvetica, sans-serif; width:98%; height:32px; font-size: 34px; color: #777777; padding-top:3px; line-height: 34px; overflow:hidden; }
.com_date, td#Events SPAN {color:#ff9933; font-size:30px;}
.head {  font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 40px; font-weight: bold; color: #55cc22; padding-top: 10px; padding-bottom: 10px; padding-right: 10px}
.listlinkbold { font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 36px; font-weight: bold; color: #3366aa; line-height: 16px; text-decoration: underline}
<%}%>
.bugNum {font-family: Miramonte; font-size: 46px; font-weight:normal; color: #333333;}
.panel {border-collapse:collapse; border:1px solid #99aacc; border-bottom:0; padding:10px;}
.botTD {width:100%; height:20px; border-bottom:1px solid #99aacc;}
#tl {width: 20px; background-image: url(../i/cornerTL.gif);border:0px;}
#tr {width: 20px; background-image: url(../i/cornerTR.gif);border:0px; align:right;}

</style>

<table width='100%' border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">
	
	<table width="100%" border="0" cellspacing="0" cellpadding="0">
  		<tr align="left" valign="top">
    	<td width="100%">
		<jsp:include page="../head.jsp" flush="true"/>
	</table>


<table width='95%'  border="0" cellspacing="0" cellpadding="0">
  <tr align="left" valign="top">
    <td>
      <table width="100%" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td>
            <table width="700" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td width="26" height="30"><a name="top">&nbsp;</a></td>
                <td width="550" height="20" align="left" valign="bottom" class="head">
				Hi, <%=fName%>
				</td>

              </tr>
            </table>
          </td>
        </tr>

        <tr>
          <td width="100%">
<!-- TAB -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Home" />
				<jsp:param name="subCat" value="Dashboard" />
				<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>
			</td>
		</tr>

        <tr><td>&nbsp;</td></tr>

<%

	String bgcolor="";
	boolean even = false;
	boolean bBold;
	int [] ids = null;
	int id;

	/////////////////////////////////////////////////////////////

%>

	<tr><td width='100%'>
	<table width='100%' border='0' cellspacing='0' cellpadding='0'>
		<tr>

<!-- left most gap on the whole page -->
		<td width='20' valign="top"><img src='../i/spacer.gif' width='20' /></td>


<%
	/***********************************************************************/
	// left column panel
	out.print("<td valign='top' width='35%'>");


	// construct content for left panel
	StringBuffer sBuf = new StringBuffer();
	sBuf.append(TABLE0);
	sBuf.append("<tr><td width='100%' valign='top'>");
	sBuf.append("<table border='0' cellspacing='0' cellpadding='0' style='word-wrap:break-word;'>");
	sBuf.append("<tr><td id='Events' class='plaintext'>Gathering info ...</td></tr>");
	sBuf.append("</table></td></tr></table>");

	// left panel table
	out.println(createDashBoardTable("What's Happening", sBuf.toString(), 0, null, null));
	out.print("</td>");


	/////////////////////
	// a vertical gap
	out.print("<td><img src='../i/spacer.gif' width='10' /></td>");


	/***********************************************************************/
	// RIGHT column panel
	out.print("<td valign='top' width='65%'>");
	out.print(TABLE0);


	/******************************************/
	// R1: my projects
	out.print("<tr><td>");
	out.print(createDashBoardTable("My Projects", getProjectList(pstuser), 0, null, null));
	out.print("</tr></td>");


	/////////////////////
	// a horizontal gap
	out.print("<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>");


	/******************************************/
	// R2: my to do
	if (isCwModule) {
		out.print("<tr><td>");
		out.print(createDashBoardTable("My To-do", "", 0, null, null));
		out.print("</tr></td>");
	}


	/////////////////////
	// a horizontal gap
	out.print("<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>");


	/***********************************************************************/
	// combined panel of 2 tables
	out.print("<tr><td>");
	out.print(TABLE0);
	out.print("<tr>");

	if (isCwModule) {
		/******************************************/
		// R3-A: open action items or defects
		out.print("<td valign='top' width='30%'>");
		out.print(TABLE0);
		out.print("<tr><td>");
		out.print(createDashBoardTable("Open Action Items", getOpenActionNum(pstuser), -100, null, null));
		out.print("</tr></td>");
		out.print("<tr><td><img src='../i/bullet_tri.gif'/>");
		out.print("<a class='listlinkbold' href='../box/worktray.jsp?projId=0'>Go to worktray</a></td></tr>");
		out.print("</table></td>");
	
		// a vertical gap
		out.print("<td width='10'><img src='../i/spacer.gif' width='10' /></td>");
	}

	/******************************************/
	// R3-B: my meetings
	out.print("<td valign='top' width='70%'>");
	out.print(TABLE0);
	out.print("<tr><td width='100%'>");
	out.print(createDashBoardTable("My Meetings", getMeetingList(pstuser), 0, null, null));
	out.print("</tr></td>");
	out.print("</table></td>");

	/***********************************************************************/
	// END: combined panel of 2 tables
	out.print("</tr></table></td></tr>");


	/////////////////////
	// a horizontal gap
	out.print("<tr><td><img src='../i/spacer.gif' height='10' /></td></tr>");


	/******************************************/
	// R4: watch list
	out.print("<tr><td>");
	out.print(createDashBoardTable("Watch List", getWatchList(pstuser, lastLogin), 0, null, null));
	out.print("</tr></td>");


	/***********************************************************************/
	// END: right column panel
	out.print("</table></td>");


	/////////////////////
	// a vertical gap at most right of Page
	out.print("<td><img src='../i/spacer.gif' width='20' /></td>");
%>


	</tr>
	</table>
	
<p>&nbsp;</p>
</td>
</tr>

</table>
	</td>
</tr>

<jsp:include page="../foot.jsp" flush="true"/>

</table>
</bgsound>

<jsp:include page="ep_expr.jsp" flush="true"/>

</body>
</html>
