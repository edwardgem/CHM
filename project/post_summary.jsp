<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_summary.java
//	Author: ECC
//	Date:		06/10/2004
//	Description:	Generate project summary file or MS Project CSV file.
//	Modification:
//		@AGQ042106	Remove all existing Project Summary attachments from the db.
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

	String NL = "\n";
	String IND = "\t";
	String DEL = ";";

	userManager uMgr = userManager.getInstance();
	planManager planObjMgr = planManager.getInstance();
	planTaskManager ptMgr = planTaskManager.getInstance();
	taskManager tkMgr = taskManager.getInstance();
	latest_resultManager lResultObjMgr = latest_resultManager.getInstance();
	projectManager pMgr = projectManager.getInstance();
	attachmentManager attMgr = attachmentManager.getInstance();

	project p = (project)pMgr.get(pstuser, Integer.parseInt(projIdS));

	String FILE_CONFIG_NAME = "pst";
	String FILE_PATH = "FILE_UPLOAD_PATH";
	ResourceBundle filebundleFile = ResourceBundle.getBundle(FILE_CONFIG_NAME);
	SimpleDateFormat Formatter = new SimpleDateFormat ("MM-dd-yy");
	String dateS = Formatter.format(new Date());

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
	// Generate Summary File

	resultManager resultMgr = resultManager.getInstance();

	int coordinatorId = Integer.parseInt((String)p.getAttribute("Owner")[0]);

	SimpleDateFormat dateFormatter = new SimpleDateFormat ("hh:mm a MMMMMMMM dd, yyyy (EEEEEEEE)");

	////////////////////////////////////////
	// create file
	fname = "PRM_" + projIdS + "_" + dateS + ".txt"; // PRM_12345_06-10-04.txt

	//If objectId directory not exist, create it.
	String filePath = filebundleFile.getString(FILE_PATH) + "/" + projIdS;
	subDirectory = new File(filePath);
	if(!subDirectory.exists())
		subDirectory.mkdirs();
	else
	{
		// need to remove the old summary file if they exist
		String nameMatch = "/" + projIdS + "/PRM_" + projIdS + "_";	// "/12345/PRM_12345_"
		ids = attMgr.findId(pstuser, "Location='" + nameMatch + "%'");
		if (ids.length > 0)
		{
			attMgr.delete(attMgr.get(pstuser, ids[0]));		// there should only be one
			p.removeAttribute("AttachmentID", String.valueOf(ids[0]));
			
			// delete the old physical file
			File [] flist = subDirectory.listFiles();
			nameMatch = "PRM_" + projIdS + "_";
			for (int i=0; i<flist.length; i++)
			{
				if (flist[i].getName().startsWith(nameMatch))
					flist[i].delete();
			}
		}
	}


	filePath += "/" + fname;			// from this point on, filePath contains the complete abs path
	f = new File(filePath);
	f.createNewFile();
	fos = new FileOutputStream(f);


	////////////////////////////////
	// ***** cover page
	// project name
	buf.append(p.getObjectName() + NL);

	// version
	buf.append("Version: " + planVersion + NL);

	// generation timestamp
	buf.append("Created Date: " + new Date().toString() + NL);
	buf.append(NL + NL + NL);
	buf.append("___________________________________" + NL + NL);


	////////////////////////////////
	// ***** project team member page
	buf.append("Project Team: " + NL + NL);

	String uname, lname;
	user aUser;

	// get team members
	Object [] teamIdList = p.getAttribute("TeamMembers");
	PstAbstractObject [] memberList = uMgr.get(pstuser, teamIdList);

	Arrays.sort(memberList, new Comparator() {
		public int compare(Object o1, Object o2)
		  {
		   user emp1 = (user) o1;
		   user emp2 = (user) o2;

		   try
		   {
			   String eName1 = emp1.getAttribute("LastName")[0] + ", " +
						emp1.getAttribute("FirstName")[0];
			   String eName2 = emp2.getAttribute("LastName")[0] + ", " +
						emp1.getAttribute("FirstName")[0];
			   return eName1.compareToIgnoreCase(eName2);
		   }
		   catch(Exception e)
		   {
			   throw new ClassCastException("Could not compare.");
		   }
		  }
	});

	for (int i = 0; i < memberList.length; i++)
	{
		aUser = (user)memberList[i];
		uid = aUser.getObjectId();
		lname = (String)aUser.getAttribute("LastName")[0];
		uname = (lname==null?"":(lname + ", ")) + aUser.getAttribute("FirstName")[0];
		buf.append(uname);
		if (uid==coordinatorId)
			buf.append(" (COORDINATOR)");
		buf.append(NL);
	}
	buf.append("___________________________________" + NL + NL);


	////////////////////////////////
	// ***** project plan page
	// list plan tasks and weblogs
	String[] levelInfo = new String[JwTask.MAX_LEVEL];
	String tStatus, latestComment, currentStatus;

	latest_result lResultObj = null;
	PstAbstractObject [] rObjList = null;

	for(int i = 0; i < targetObjList.length; i++)
	{	// a list of plan task
		planTask ptargetObj = (planTask)targetObjList[i];
		pTaskId = ptargetObj.getObjectId();

		// only show non-DEPRECATED plantask
		currentStatus = (String)ptargetObj.getAttribute("Status")[0];
		if (currentStatus.equals(task.DEPRECATED))
			continue;

		pName = (String)ptargetObj.getAttribute("Name")[0];
		taskId = Integer.parseInt((String)ptargetObj.getAttribute("TaskID")[0]);
		Object [] pLevel = ptargetObj.getAttribute("Level");
		Object [] pOrder = ptargetObj.getAttribute("Order");

		// Owner must be stored in task, otherwise once you load a new version
		// of plan (a new set of plantask), you lost the owner in history.
		// First get the task associated to this taskplan
		tk = (task)tkMgr.get(pstuser, taskId);

		ownerIdS = (String)tk.getAttribute("Owner")[0];
		tStatus = (String)tk.getAttribute("Status")[0];

		latestComment = null;
		Date lastUpdated = null;
		int [] rObjIds = lResultObjMgr.findId(pstuser, "get_latest_result", tk);
		if (rObjIds.length != 0)
		{
			lResultObj = (latest_result)lResultObjMgr.get(pstuser, rObjIds[0]);
			latestComment = (String)lResultObj.getAttribute("LastComment")[0];
			lastUpdated = (Date)lResultObj.getAttribute("LastUpdatedDate")[0];
		}

		if (lastUpdated == null)
			lastUpdated = (Date)tk.getAttribute("CreatedDate")[0];

		int level = ((Integer)pLevel[0]).intValue();
		int order = ((Integer)pOrder[0]).intValue();

		int width = 5 + 22 * level;

		order++;
		if (level == 0)
		{
			levelInfo[level] = String.valueOf(order);
		}
		else
		{
			levelInfo[level] = levelInfo[level - 1] + "." + order;
		}
		level++;

		buf.append(levelInfo[level-1] + "  ");
		buf.append(pName);

		// owner
		if (ownerIdS != null)
		{
			// ECC: need to optimize this in the near future
			if (!ownerIdS.equals(lastOwner))
				empObj = (user)uMgr.get(pstuser,Integer.parseInt(ownerIdS));
			uid = empObj.getObjectId();
			lastOwner = ownerIdS;
		}
		buf.append(" (" + (String)empObj.getAttribute("FirstName")[0]
			+ " " + (String)empObj.getAttribute("LastName")[0] + ")" + NL + NL);

		// ********** list task weblogs **********

		// get the weblog (result) objects associated to this task (TaskID is used to
		// store ProjID or TownID or TaskID.  It all depends on the Type attribute.
		int [] resultIds = resultMgr.findId(pstuser, "(TaskID='" + tk.getObjectId() + "') && (Type='Task')");
		PstAbstractObject [] blogList = resultMgr.get(pstuser, resultIds);

		// sort the result by create date.  Display latest postings first.
		Arrays.sort(blogList, new Comparator()
		{
			public int compare(Object o1, Object o2)
			{
				try{
				Date d2 = (Date)((result)o2).getAttribute("CreatedDate")[0];
				Date d1 = (Date)((result)o1).getAttribute("CreatedDate")[0];
				return d2.compareTo(d1);
				}catch(Exception e){
					return 0;}
			}
		});

		//
		// we will need to retrieve archives in the near future
		//

		Date createDate;
		String creatorIdS;

		String bText;
		Object bTextObj;

		for (int j = 0; j < blogList.length; j++)
		{
			result blog = (result)blogList[j];
			createDate = (Date)blog.getAttribute("CreatedDate")[0];
			creatorIdS = (String)blog.getAttribute("Creator")[0];
			aUser = (user)uMgr.get(pstuser, Integer.parseInt(creatorIdS));
			lname = (String)aUser.getAttribute("LastName")[0];
			uname =  aUser.getAttribute("FirstName")[0] + " " + (lname==null?"":lname);

			buf.append("Posted by: " + uname.toUpperCase());
			buf.append(" at " + dateFormatter.format(createDate) + NL );	// DATE

			// blog TEXT
			bTextObj = blog.getAttribute("Comment")[0];
			bText = (bTextObj==null)?"":new String((byte[])bTextObj);
			bText = bText.replaceAll("<li>", "\n- ");
			bText = bText.replaceAll("<p>", "\n\n");
			bText = bText.replaceAll("<br>", "\n");
			bText = bText.replaceAll("<\\S[^>]*>", "");		// strip HTML tag
			bText = bText.replaceAll("&nbsp;", " ");			// there will be HTML spaces
			bText = bText.replaceAll("&quot;", "\"");

			buf.append(bText + NL);

		}	// end for loop for bloglist

		buf.append(NL + NL);
	}	// end for loop for tasklist

	buf.append(NL);

	// save buffer to file
	fos.write(buf.toString().getBytes());
	fos.flush();
	fos.close();
		
	// create the attachment object (the create() call will update the index)
	attachment att = (attachment)attMgr.create(pstuser,
			String.valueOf(pstuser.getObjectId()),
			"/" + projIdS + "/" + fname,				// relPath
			"txt",
			projIdS,
			attachment.TYPE_PROJECT);
	
	///////////////////////////////////////////////////
	// append the attribute
	p.appendAttribute("AttachmentID", String.valueOf(att.getObjectId()));
	p.setAttribute("LastUpdatedDate", new Date());
	pMgr.commit(p);

	response.sendRedirect("proj_profile.jsp?projId="+projIdS);	// default
%>
