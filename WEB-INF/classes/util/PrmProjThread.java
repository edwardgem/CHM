////////////////////////////////////////////////////
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
//
//	File:	PrmProjThread.java
//	Author:	ECC
//	Date:	05/06/05
//	Description:
//		Run background thread to construct project plan.
//
//	Modification:
//		@ECC070307	Support option to show only latest revision file attachment.
//		@ECC103008	Support link attachments to task.
//		@ECC012909	Google docs.
//
////////////////////////////////////////////////////////////////////

package util;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.Stack;
import java.util.Vector;

import javax.servlet.http.HttpSession;

import oct.codegen.attachment;
import oct.codegen.attachmentManager;
import oct.codegen.latest_result;
import oct.codegen.latest_resultManager;
import oct.codegen.planTask;
import oct.codegen.planTaskManager;
import oct.codegen.result;
import oct.codegen.resultManager;
import oct.codegen.task;
import oct.codegen.taskManager;
import oct.codegen.userManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstAbstractObject;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;

public class PrmProjThread extends Thread
{
	public static final int	CR			= 1;
	public static final int	PTM			= 2;

	public static int FILLED_INFO		= 0;		// 0=no info; 1=PTM info filled; 2=CR info filled; 3=both PTM and CR info filled
	static taskManager tMgr				= null;
	static attachmentManager aMgr		= null;
	static latest_resultManager lrMgr 	= null;
	static planTaskManager ptMgr 		= null;
	static resultManager rMgr			= null;
	static userManager uMgr				= null;
	static String PLUS					= "+";
	static String S;
	static boolean isBlogModule			= ( ((S=Util.getPropKey("pst", "MODULE"))!=null && S.equalsIgnoreCase("Blog"))
				|| ((S=Util.getPropKey("pst", "APPLICATION"))!=null && S.equalsIgnoreCase("PRM")) );

	HttpSession session;
	PstUserAbstractObject pstuser;
	String latestPlanIdS;
	String projIdS;
	boolean isCR;

	private static Logger l = PrmLog.getLog();

	static {
		try {
			aMgr = attachmentManager.getInstance();
			tMgr = taskManager.getInstance();
			lrMgr = latest_resultManager.getInstance();
			ptMgr = planTaskManager.getInstance();
			rMgr = resultManager.getInstance();
			uMgr = userManager.getInstance();
		}
		catch (PmpException e){}
	}

	public PrmProjThread(HttpSession sess, PstUserAbstractObject u, String planIdS, String pjIdS, boolean cr)
	{
		session = sess;
		pstuser = u;
		latestPlanIdS = planIdS;
		projIdS = pjIdS;
		isCR = cr;						// true if called by the cr.jsp; false if called by proj_plan.jsp
		FILLED_INFO = 0;				// reset info type: this is a reload of a new project space
	}

	@SuppressWarnings("unchecked")
	public void run()
	{
		try
		{
			Stack planStack = setupPlan(0, session, (Stack)session.getAttribute("planStack"),
					pstuser, projIdS, latestPlanIdS, isCR);
			session.removeAttribute("planStack");
			session.setAttribute("planStack", planStack);
		}
		catch (Exception e)
		{
			e.printStackTrace();
			l.error("***** Fail to load project plan.");
		}
		session.setAttribute("planComplete", "true");				// Commit Transaction
	}

	// setupPlan(): set up the planStack
	@SuppressWarnings("unchecked")
	public static Stack setupPlan(	int caller,					// 0=fill all levels
									HttpSession sess,
									Stack currentStack,
									PstUserAbstractObject u,
									String projIdS,
									String latestPlanIdS,
									boolean isCR)
		throws Exception
	{
		//if ( ((FILLED_INFO & CR)!=0 && isCR)
		//	|| ((FILLED_INFO & PTM)!=0 && !isCR) )
		// return currentStack;
		// System.out.println("setupPlan(" + caller + "): projId="+projIdS);
		String expr = "";
		if (caller > 0)
			expr = " && Level=0";	// am I only loading level 0 or all levels?

		String latestComment, taskIdS;
		Date lastUpdated;
		latest_result lResultObj = null;
		Object [] pLevel;
		Object [] pOrder;
		int level, order;
		task t;
		HashMap<String,String> taskNameMap = null;
		String[] levelInfo = new String[JwTask.MAX_LEVEL];

		Vector rPlan = null;

		// 0=no info; 1=PTM info filled; 2=CR info filled; 3=both PTM and CR info filled
		int iFilled = 0;

		// I might already have PTM info and is now filling CR info (or vice versa)
		boolean bAlreadyHasPlan = false;
		if (caller==0 && sess!=null)
		{
			Integer io = (Integer)sess.getAttribute("filledInfo");
			if (io != null) iFilled = io.intValue();
			// if (iFilled >= (CR|PTM)) iFilled = 0;      	// reset: this is a new project
		}

		// check to see if I have a half-filled planStack
		if (currentStack != null)
		{
			//System.out.println("   use old plan stack ("+ iFilled + ")");
			bAlreadyHasPlan = true;
			rPlan = (Vector)currentStack.peek();
			if (sess != null) {
				// retrieve the existing map and continue filling
				taskNameMap = (HashMap<String, String>) sess.getAttribute("taskNameMap");
			}
		}
		else
		{
			// dealing with a new project
			//System.out.println("   new plan stack");
			currentStack = new Stack();
			rPlan = new Vector();
			currentStack.push(rPlan);
			iFilled = 0;

			// if there was another open project, this map will correctly overwrite the old map below
			taskNameMap = new HashMap<String,String>(256);
		}


		expr = "PlanID='" + latestPlanIdS + "' && Status!='" +task.DEPRECATED + "'" + expr;
		int [] ids;
		try{ids = ptMgr.findId(u, expr);}
		catch (Exception e){e.printStackTrace(); return null;}

		PstAbstractObject [] pTaskList = ptMgr.get(u, ids);
		Util.sortInteger(pTaskList, "PreOrder");

		Hashtable rTask;
		String uid=null, dept, taskName;
		int frequency;
		Integer io;
		int [] blogIds;
		String s;

		for (int i=0; i < pTaskList.length; i++)
		{
			// pTask is the persistent Task
			// rTask is the ram task which is in cache
			planTask pTask = (planTask) pTaskList[i];
			if (bAlreadyHasPlan)
				rTask = (Hashtable)rPlan.elementAt(i);
			else
				rTask = new Hashtable();
			taskIdS = (String)pTask.getAttribute("TaskID")[0];
			t = (task)tMgr.get(u, taskIdS);
			if (!isCR)
			{
				// called by proj_plan.jsp
				int [] rObjIds = lrMgr.findId(u, "get_latest_result", t);
				latestComment = null;
				lastUpdated = null;
				if (rObjIds.length != 0)
				{
					lResultObj = (latest_result)lrMgr.get(u, rObjIds[0]);
					latestComment = (String)lResultObj.getAttribute("LastComment")[0];
					lastUpdated = (Date)lResultObj.getAttribute("LastUpdatedDate")[0];
					rTask.put("LastComment", latestComment);
					rTask.put("LastUpdatedDate", lastUpdated);
				}
				//rTask.put("Status", task.ORIGINAL);
			}
			else
			{
				// called by cr.jsp: need to get attachments
				Object [] attmtList = t.getAttribute("AttachmentID");
				int [] aids = Util2.toIntArray(attmtList);
				ids = aMgr.findId(u, "Link='" + t.getObjectId() + "'");		// @ECC103008
				aids = Util2.mergeIntArray(aids, ids);
				if (aids.length>0)
				{
				    AttInfo [] attArr;	// = new AttInfo[aids.length];
				    ArrayList attList = new ArrayList(512);
					AttInfo a;
					String id, fname, author, shareStr, fURL, tOwnerIdS;
					Date date;
					Object [] shareArr;
					attachment attmtObj = null;
					for (int j=0; j< aids.length; j++)
					{
						try {attmtObj = (attachment)aMgr.get(u, aids[j]);}
						catch (PmpException e) {l.error("error getting attachement Id [" + aids[j] + "]"); continue;}
						id = String.valueOf(aids[j]);
						fname = attmtObj.getFileName();
						try
						{
							uid = (String)attmtObj.getAttribute("Owner")[0];
							if (uid!=null && !uid.equals("-1"))
								author = attmtObj.getOwnerDisplayName(u);
							else
								author = "-";
						}
						catch (PmpException e)
						{
							l.info("Removed bad ownerId (" + uid + ") from attachment [" + attmtObj.getObjectId() + "]");
							author = "-";
							uid = "-1";
							attmtObj.setAttribute("Owner", "-1");
							aMgr.commit(attmtObj);
						}
						date = (Date)attmtObj.getAttribute("CreatedDate")[0];
						dept = (String)attmtObj.getAttribute("DepartmentName")[0];
						io = (Integer)attmtObj.getAttribute("Frequency")[0];
						if (io != null) frequency = io.intValue();
						else frequency = 0;

						// share ids
						shareStr = "";
						shareArr = attmtObj.getAttribute("ShareID");
						for (int k=0; k<shareArr.length; k++)
						{
							try {s = uMgr.get(u, Integer.parseInt((String)shareArr[k])).getObjectName();}
							catch (Exception e) {continue;}
							if (shareStr.length() > 0) shareStr += ", ";
							shareStr += s;
						}

						// Google URL link
						s = (String)attmtObj.getAttribute("Location")[0];
						if (s.startsWith("http:")) fURL = s;
						else fURL = null;
						a = new AttInfo(id, fname, fURL, uid, author, date, frequency, dept, shareStr,
								(Arrays.binarySearch(ids, aids[j])>=0));
						attList.add(a);
						tOwnerIdS = t.getStringAttribute("Owner");
						if (!StringUtil.isNullOrEmptyString(tOwnerIdS))
							rTask.put("UserID", tOwnerIdS);
						else
							l.error("PrmProjThread: null Owner for task [" + t.getObjectId() + "]");
					}
					attArr = (AttInfo []) attList.toArray(new AttInfo[0]);
					setRevisionHideShow(attArr);
					rTask.put("AttInfo", attArr);
				}	// if there are any attachment in CR (include link doc)
			}

			// @ECC081407
			if (!isCR || isBlogModule)
			{
				// need to get blog num
				blogIds = rMgr.findId(u, "(TaskID='" + taskIdS + "') && (Type='" + result.TYPE_TASK_BLOG + "')");
				rTask.put("BlogNum", String.valueOf(blogIds.length));
			}

			if (iFilled <= 0)
			{
				pLevel = pTask.getAttribute("Level");
				pOrder = pTask.getAttribute("Order");
				taskName = (String)pTask.getAttribute("Name")[0];
				
				// don't know why we hit a bug where taskName is null and got into an infinite loop, fix as follows:
				if (taskName == null) taskName = "-";

				rTask.put("PlanID", latestPlanIdS);	// depends on set up above
				rTask.put("Order", pOrder);
				rTask.put("Level", pLevel);
				rTask.put("Name", taskName);
				rTask.put("Status", task.ORIGINAL);
				rTask.put("TaskID", taskIdS);
				rTask.put("PlanTaskID", String.valueOf(pTask.getObjectId()));
				rTask.put("ProjectID", projIdS);
				rTask.put("Task", t);

				level = ((Integer)pLevel[0]).intValue();
				order = ((Integer)pOrder[0]).intValue() + 1;

				if (level == 0) {
					rTask.put("Expand", PLUS);
					levelInfo[level] = String.valueOf(order);
				}
				else
					levelInfo[level] = levelInfo[level - 1] + "." + order;

				// perhaps I should map to a string with URL link for convenience?
				if (sess != null) {
					taskNameMap.put(taskIdS, levelInfo[level] + " " + taskName);
				}
			}
			if (!bAlreadyHasPlan) rPlan.addElement(rTask);
		}

		// remember what info I have filled
		if (caller == 0)
		{
			// I am filling all levels
			if (isCR) iFilled |= CR;
			else iFilled |= PTM;
			if (sess != null)
				sess.setAttribute("filledInfo", Integer.valueOf(iFilled));
		}

		if (taskNameMap!=null && sess!=null)
			sess.setAttribute("taskNameMap", taskNameMap);

		return currentStack;
	}

	// @ECC070307
	private static void setRevisionHideShow(AttInfo [] attArr)
	{
		if (attArr.length <= 1) return;

		Util2.sortAttInfoArray(attArr, "fn", true);		// sort by filename

		AttInfo att, latestAtt = null;
		int idx;
		String fileName, pureName, latestPureName=null;
		for (int i=0; i<attArr.length; i++)
		{
			att = (AttInfo)attArr[i];
			if (att == null) continue;
			fileName = att.filename;

			// @ECC070307 option to show only lastest revision files
			if ((idx = fileName.lastIndexOf('(')) != -1)
			{
				// versioning is with this filename
				if (latestAtt == null)
				{
					latestAtt = att;		// set up initial one for this filename series
					latestPureName = att.filename.substring(0, idx-1);
					continue;
				}
				pureName = fileName.substring(0, idx-1);
				if (pureName.equals(latestPureName))
				{
					try
					{
						if ( Integer.parseInt(att.attid) < Integer.parseInt(latestAtt.attid) )
						{
							att.bShow = false;
						}
						else
						{
							latestAtt.bShow = false;
							latestAtt = att;
						}
					}
					catch (Exception e){}
				}
				else
				{
					latestAtt = att;	// this att is the beginning of another series
					latestPureName = pureName;
				}
			}
			else
				latestAtt = null;		// this is not a versioning filename series
		}
	}	// END: setRevisionHideShow()

	/**
	 * Create a background thread to setup the project plan
	 * @param session
	 * @param u
	 * @param latestPlanIdS
	 * @param projIdS
	 * @param bChangeCurrentPlan
	 */
	public static void backgroundConstructPlan(
			HttpSession session, PstUserAbstractObject u,
			String latestPlanIdS, String projIdS,
			boolean bChangeCurrentPlan, boolean isCR)
	{
		PrmProjThread th = (PrmProjThread)session.getAttribute("projThread");
		if (th!=null && th.isAlive())
			return;		// simply let it finishes
		if (bChangeCurrentPlan) session.removeAttribute("planStack");	// change plan: throw away old stack
		session.setAttribute("planComplete", "false");					// Begin Transaction
		th = new PrmProjThread(session, u, latestPlanIdS, projIdS, isCR);
		th.start();
		session.setAttribute("projThread", th);
	}

}
