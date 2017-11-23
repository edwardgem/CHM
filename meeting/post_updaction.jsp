<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_updaction.jsp
//	Author: ECC
//	Date:		03/9/2005
//	Description:	Delete an action item or update the status.
//	Modification:
//		@050105ECC	Support deleting Action/Decision from project (no link to meeting)
//		@ECC082305a	Support update of action/decision/issues.  Save mtg minute for safety.
//
/////////////////////////////////////////////////////////////////////
//
%>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />


<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");
	
	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	String backPage = request.getParameter("backPage");
	String midS = request.getParameter("mid");
	String oidS = request.getParameter("oid");		// non-null if this is an update of existing item
	String s = request.getParameter("run");
	boolean isRun = (s!=null && s.length()>0);

	String projIdS = null;
	if (midS!=null && midS.length() <= 0) midS = null;
	if (midS == null)
		projIdS = request.getParameter("projId");	// caller is from proj_action.jsp -> upd_action.jsp

	actionManager aMgr = actionManager.getInstance();
	bugManager bMgr = bugManager.getInstance();
	PstAbstractObject obj;

	java.text.SimpleDateFormat df = new java.text.SimpleDateFormat("MM/dd/yyyy");
	Date today = df.parse(df.format(new Date()));

	// @ECC082305a
	if (oidS!=null && oidS.length()>0)
	{
		// update action/decision/issue contents
		PstManager mgr = null;
		String type = request.getParameter("type");
		String subj = request.getParameter("Description");
		if (subj != null) {
			subj = subj.replaceAll("\\\\", "");
		}
		String prio = request.getParameter("Priority");
		String pidS = request.getParameter("projId");
		String bIdS = request.getParameter("BugId");
		String owner = request.getParameter("Owner");
		String status = request.getParameter("Status");

		if (type.equals(action.TYPE_ACTION) || type.equals(action.TYPE_DECISION))
		{
			mgr = aMgr;
			obj = mgr.get(pstuser, oidS);
			
			// handle special operations
			String op = request.getParameter("op");
			if (op!=null) {
				if (op.equals("delete")) {
					// delete the item
					// this will clean up steps and blogs
					aMgr.delete(obj);					
					response.sendRedirect(backPage);		// only called by upd_action.jsp & proj_action.jsp - use its backPage
					return;
				}
			}
			
			obj.setAttribute("Subject", subj);
			obj.setAttribute("BugID", bIdS);
			obj.setAttribute("Type", type);

			if (type.equals(action.TYPE_ACTION))
			{
				String [] respA = request.getParameterValues("Responsible");
				obj.setAttribute("Responsible", null);
				for (int i=0; respA!=null && i<respA.length; i++)
				{
					obj.appendAttribute("Responsible", respA[i]);
				}
				String expire = request.getParameter("Expire");
				Date exDt = df.parse(expire);
				obj.setAttribute("ExpireDate", exDt);
				if (status!=null)
				{
					if (status.equals(action.OPEN))
					{
						if (exDt.before(today))
							status = action.LATE;
					}
					else if (status.equals(action.DONE))
						obj.setAttribute("CompleteDate", today);
					((action)obj).setStatus(pstuser, status);
				}
				else
				{
					// disabled case (LATE)
					status = (String)obj.getAttribute("Status")[0];
					if (status.equals(action.LATE) && !exDt.before(today))
						((action)obj).setStatus(pstuser, action.OPEN);	// re-open
				}
				
				obj.setAttribute("Owner", owner);
				PrmUpdateCounter.updateOrCreateCounterArray(midS, PrmUpdateCounter.AIINDEX);
				
			}	// END if TYPE_ACTION
			
			// Decision
			else {
				PrmUpdateCounter.updateOrCreateCounterArray(midS, PrmUpdateCounter.DCINDEX);
			}

			// check if adding comment (blog) to action
			String text = request.getParameter("Comment");
			if (text != null) {
				text = text.trim();
				if (text.length() > 0) {
					resultManager rMgr = resultManager.getInstance();
					PstAbstractObject blogObj = rMgr.create(pstuser);

					blogObj.setAttribute("CreatedDate", new Date());
					blogObj.setAttribute("Creator", String.valueOf(pstuser.getObjectId()));
					blogObj.setAttribute("Type", result.TYPE_ACTN_BLOG);
					blogObj.setAttribute("TaskID", String.valueOf(obj.getObjectId()));
					blogObj.setAttribute("Comment", text.getBytes("utf-8"));
					rMgr.commit(blogObj);
				}
			}
		}	// END if TYPE_ACION || TYPE_DECISION
		
		else
		{
			// Issue
			mgr = bMgr;
			obj = mgr.get(pstuser, oidS);
			obj.setAttribute("Synopsis", subj);
			obj.setAttribute("Creator", owner);
			if (status != null)						// if radio is disabled, it will be null here
				obj.setAttribute("State", status);
			PrmUpdateCounter.updateOrCreateCounterArray(midS, PrmUpdateCounter.ISINDEX);
		}

		obj.setAttribute("Priority", prio);
		
		s = request.getParameter("ChangeProject");
		if (s!=null && s.equals("on"))
			obj.setAttribute("ProjectID", pidS);		// move action item to new project

		mgr.commit(obj);
	}
	else
	{
		// Either delete or update status only: get the list of obj ids
		for (Enumeration e = request.getParameterNames() ; e.hasMoreElements() ;)
		{
			String temp = (String)e.nextElement();
			if (temp.startsWith("update_"))
			{
				// change status for action item
				String act = request.getParameter(temp);
				if (act == null) continue;

				oidS = temp.substring(7);
				obj = aMgr.get(pstuser, oidS);

				if (act.equals(action.DONE) || act.equals(action.CANCEL))
				{
					obj.setAttribute("Status", act);
					if (act.equals(action.DONE))
						obj.setAttribute("CompleteDate", today);
					aMgr.commit(obj);
				}
			}
			else if (temp.startsWith("delete_"))
			{
				// delete action items or decisions
				oidS = temp.substring(7);
				try
				{
					obj = aMgr.get(pstuser, oidS);
					((action)obj).deleteAction(pstuser);
					//aMgr.delete(obj);
				}
				catch (PmpException ee)
				{
					// assume that the object is a bug
					obj = bMgr.get(pstuser, oidS);
					((bug)obj).deleteBug(pstuser);
					//bMgr.delete(obj);

					// all actions that reference this bug needs to be cleared
					int [] ids = aMgr.findId(pstuser, "BugID='" + oidS + "'");
					for (int i=0; i<ids.length; i++)
					{
						obj = aMgr.get(pstuser, ids[i]);
						obj.setAttribute("BugID", null);
						aMgr.commit(obj);
					}
				}
			}
		}

		// @ECC082305a save meeting minutes for safety
		String mText = request.getParameter("mtext");
		if (mText!=null && midS!=null)
		{
			// came from mtg_live.jsp
			meetingManager mMgr = meetingManager.getInstance();
			meeting mtg = (meeting)mMgr.get(pstuser, midS);
			//mText = mText.replaceAll("<p></p>", "").trim();
			mtg.setAttribute("Note", mText.getBytes("utf-8"));
			mMgr.commit(mtg);
		}
	}

	// in order to jump to page location with #, we need to use javaScript
	String loc = null;
	if (backPage!=null && backPage.length()>0)
	{
		if (midS != null && backPage.indexOf("mid")<0) backPage += "?mid=" + midS + "&refresh=1";
		loc = backPage;				// upd action after mtg is over: from mtg_view.jsp or mtg_update2.jsp
	}
	else if (isRun)
		loc = "mtg_live.jsp?mid=" + midS + "&run=true#action";
	else
		loc = "../project/proj_action.jsp?projId=" + projIdS + "&mid=" + midS;

%>
<script language="JavaScript">
<!--
	window.location='<%=loc%>';
//-->
</script>
