<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_msp_export.java
//	Author: ECC
//	Date:		11/10/2004
//	Description:	Export MS Project CSV file.
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.util.file.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.PepCommentVector" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "com.oreilly.servlet.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />


<%
	// Attachment-JW_12345_06-10-04.txt
	String projIdS = request.getParameter("projId");
	if ((pstuser instanceof PstGuest) || (projIdS == null))
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}

	final String FILE_PREFIX = "CPM_MSP_";
	String NL = "\n";
	String IND = "\t";
	String DEL = ",";

	userManager uMgr = userManager.getInstance();
	planManager planObjMgr = planManager.getInstance();
	planTaskManager ptMgr = planTaskManager.getInstance();
	taskManager tkMgr = taskManager.getInstance();
	latest_resultManager lResultObjMgr = latest_resultManager.getInstance();
	projectManager pMgr = projectManager.getInstance();
	project p = (project)pMgr.get(pstuser, Integer.parseInt(projIdS));

	String FILE_PATH = "FILE_UPLOAD_PATH";
	SimpleDateFormat df0 = new SimpleDateFormat ("MM-dd-yy");	// for filename
	SimpleDateFormat df = new java.text.SimpleDateFormat("MM/dd/yyyy");
	String dateS = df0.format(new Date());
	Date today = new Date(df.format(new Date()));

	String fname;
	File subDirectory, f;
	FileOutputStream fos;
	StringBuffer buf = new StringBuffer();

	task tk;
	int taskId;
	int pTaskId;
	String pName;
	user empObj = null;
	String ownerIdS, lastOwner = "";
	int uid;

	// need to get the latest plan for this project
	int [] ids = planObjMgr.findId(pstuser, "Status='Latest' && ProjectID='"+projIdS+"'");
	PstAbstractObject [] targetObjList = planObjMgr.get(pstuser, ids);

	// there is only one plan which is latest for this project
	plan latestPlan = (plan)targetObjList[0];

	// Versioning
	String planVersion = (String)latestPlan.getAttribute("Version")[0];

	// Get plan tasks for this project plan
	ids = ptMgr.findId(pstuser, "get_plan_tasks", latestPlan);
	targetObjList = ptMgr.get(pstuser, ids);

	Arrays.sort(targetObjList, new Comparator()
	{
		public int compare(Object o1, Object o2)
		{
			try{
			Integer d2 = (Integer)((planTask)o2).getAttribute("PreOrder")[0];
			Integer d1 = (Integer)((planTask)o1).getAttribute("PreOrder")[0];
			return d1.compareTo(d2);
			}catch(Exception e){System.out.println("Internal error sorting plan task list [currentProject.jsp].");
				return 0;}
		}
	});


	////////////////////////////////////////////////////
	// Export of MS Project

	// ID;TaskID;Level;Outline;Name;Predecessors;StartDate;ExpireDate;CompleteDate;Resource
	// ID;TaskID;Level;Outline;Name;Predecessors;StartDate;ActualStartDate;ExpireDate;CompleteDate;Resource

	attachmentManager attMgr = attachmentManager.getInstance();
	attachment attObj;

	// generate MS Project CSV file
	fname = FILE_PREFIX + projIdS + "_" + dateS + ".csv"; // CPM_MSP_12345_06-10-04.csv
	String relPath = "/" + projIdS;
	String filePath = Util.getPropKey("pst", FILE_PATH) + relPath;
	relPath = relPath + "/" + fname;

	//If objectId directory not exist, create it.
	subDirectory = new File(filePath);
	if(!subDirectory.exists())
		subDirectory.mkdirs();
	else
	{
		// need to remove the old summary file if they exist
		File [] flist = subDirectory.listFiles();
		String nameMatch = FILE_PREFIX + projIdS + "_";	// removed "Attachment-"
		String s;
		for (int i=0; i<flist.length; i++)
		{
			if (flist[i].getName().startsWith(nameMatch))
			{
				// delete this file
				String fn = flist[i].getName();
				flist[i].delete();

				// remove the AttachmentID from project
				ids = attMgr.findId(pstuser, "Location='%" + fn + "'");
				if (ids.length > 0)
				{
					attachment aObj = (attachment)attMgr.get(pstuser, ids[i]);
					attMgr.delete(aObj);
					p.removeAttribute("AttachmentID", String.valueOf(ids[0]));
				}
			}
		}
	}

	filePath += "/" + fname;		// filePath now has the absolute path name
	f = new File(filePath);
	f.createNewFile();
	fos = new FileOutputStream(f);
	Date oriStart, oriExpire, start, expire, complete, actualStart;
	String predecessors;
	Object [] dependency;

	// build hash to find predecessors.
	HashMap hash = new HashMap();
	for (int i = 0; i < targetObjList.length; i++)
	{
		planTask ptargetObj = (planTask)targetObjList[i];

		// only show non-DEPRECATED plantask
		if (((String)ptargetObj.getAttribute("Status")[0]).equals(task.DEPRECATED))
			continue;
		taskId = Integer.parseInt((String)ptargetObj.getAttribute("TaskID")[0]);
		hash.put(new Integer(taskId), new Integer(i+1));	// task sequence # starts from "1"
	}

	// start preparing the file content
	// file cannot start with "ID" or get Excel get SYLK file format error
	buf.append("No.,TaskID,Resource,Level,Name,Dependency,OriStartDate,OriExpireDate,StartDate,ExpireDate,ActualStartDate,CompleteDate,Outline");
	buf.append(NL);

/*		// first entry is the project itself: sequence # = 1
	buf.append(1); buf.append(DEL);
	buf.append(projIdS); buf.append(DEL);
	buf.append(p.getObjectName()); buf.append(DEL);
	buf.append(DEL);
	buf.append(Formatter.format((Date)p.getAttribute("StartDate")[0])); buf.append(DEL);
	buf.append(Formatter.format((Date)p.getAttribute("ExpireDate")[0])); buf.append(DEL);
	Date dt = (Date)p.getAttribute("CompleteDate")[0];
	if (dt != null)
		buf.append(Formatter.format(dt));
	buf.append(DEL);
	empObj = (user)uMgr.get(pstuser,Integer.parseInt((String)p.getAttribute("Owner")[0]));
	buf.append(empObj.getObjectName());
	buf.append(NL);
*/

	// task list
	String[] levelInfo = new String[JwTask.MAX_LEVEL];
	for(int i = 0; i < targetObjList.length; i++)
	{	// a list of plan task
		planTask ptargetObj = (planTask)targetObjList[i];
		pTaskId = ptargetObj.getObjectId();
		taskId = Integer.parseInt((String)ptargetObj.getAttribute("TaskID")[0]);
		tk = (task)tkMgr.get(pstuser, taskId);

		// only show non-DEPRECATED plantask
		if (((String)ptargetObj.getAttribute("Status")[0]).equals(task.DEPRECATED))
			continue;

		pName = (String)ptargetObj.getAttribute("Name")[0];
		// surround name with double quotes if needed
		pName = "\"" + pName + "\"";

		int level = ((Integer)ptargetObj.getAttribute("Level")[0]).intValue();
		int order = ((Integer)ptargetObj.getAttribute("Order")[0]).intValue() + 1;
		if (level == 0)
			levelInfo[level] = String.valueOf(order);
		else
			levelInfo[level] = levelInfo[level - 1] + "." + order;

		//  Predecessors: don't use parent-child, use Dependency attribute
		predecessors = "";
		dependency = tk.getAttribute("Dependency");
		if (dependency[0] != null)
		{
			// use planTask to look for taskID
			for (int j=0; j<dependency.length; j++)
			{
				Object iObj = new Integer((String)dependency[j]);
				iObj = hash.get(iObj);
				if (iObj == null) {
					System.out.println("!!! post_msp_export.jsp (" + projIdS + ") - task [ "
					                        + dependency[j] + "] not found.");
					continue;
				}
				if (predecessors.length() > 0) predecessors = predecessors + ",";
				predecessors += iObj.toString();
			}
		}

		oriStart = (Date)tk.getAttribute("OriginalStartDate")[0];
		oriExpire = (Date)tk.getAttribute("OriginalExpireDate")[0];
		start = (Date)tk.getAttribute("StartDate")[0];
		expire = (Date)tk.getAttribute("ExpireDate")[0];
		actualStart = (Date)tk.getAttribute("EffectiveDate")[0];
		complete = (Date)tk.getAttribute("CompleteDate")[0];

		// task resource: owner
		ownerIdS = (String)tk.getAttribute("Owner")[0];
		if (ownerIdS != null)
		{
			// ECC: need to optimize this in the near future
			if (!ownerIdS.equals(lastOwner))
				empObj = (user)uMgr.get(pstuser,Integer.parseInt(ownerIdS));
			lastOwner = ownerIdS;
		}

		buf.append(i+1); buf.append(DEL);
		buf.append(taskId); buf.append(DEL);
		buf.append(empObj.getObjectName()); buf.append(DEL);
		buf.append(levelInfo[level]); buf.append(DEL);
		buf.append(pName); buf.append(DEL);
		buf.append(predecessors); buf.append(DEL);		// dependency

		if (oriStart != null)
			buf.append(df.format(oriStart));
		buf.append(DEL);
		if (oriExpire != null)
			buf.append(df.format(oriExpire));
		buf.append(DEL);
		if (start != null)
			buf.append(df.format(start));
		buf.append(DEL);
		if (expire != null)
			buf.append(df.format(expire));
		buf.append(DEL);
		if (actualStart != null)
			buf.append(df.format(actualStart));
		buf.append(DEL);
		if (complete != null)
			buf.append(df.format(complete));
		 buf.append(DEL);

		buf.append(level+1);
		buf.append(NL);
	}

	// save buffer to file
	fos.write(buf.toString().getBytes());
	fos.flush();
	fos.close();

	attObj = (attachment)attMgr.create(pstuser,
			String.valueOf(pstuser.getObjectId()),
			relPath,
			"csv",
			projIdS,
			attachment.TYPE_PROJECT);
	p.appendAttribute("AttachmentID", String.valueOf(attObj.getObjectId()));
	p.setAttribute("LastUpdatedDate", new Date());
	pMgr.commit(p);

	response.sendRedirect("proj_profile.jsp?projId="+projIdS);	// default

%>
