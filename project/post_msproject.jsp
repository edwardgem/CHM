<%
//
//	Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_msproject.java
//	Author: ECC
//	Date:		11/10/2004
//	Description:	Import and export MS Project CSV file.
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
	String type = request.getParameter("type");

	String NL = "\n";
	String IND = "\t";
	String DEL = ";";

	userManager uMgr = userManager.getInstance();
	planManager planObjMgr = planManager.getInstance();
	planTaskManager ptMgr = planTaskManager.getInstance();
	taskManager tkMgr = taskManager.getInstance();
	latest_resultManager lResultObjMgr = latest_resultManager.getInstance();
	projectManager pMgr = projectManager.getInstance();
	project p = (project)pMgr.get(pstuser, Integer.parseInt(projIdS));

	String FILE_CONFIG_NAME = "pst";
	String FILE_PATH = "FILE_UPLOAD_PATH";
	ResourceBundle filebundleFile = ResourceBundle.getBundle(FILE_CONFIG_NAME);
	String filePath = filebundleFile.getString(FILE_PATH) + File.separator + projIdS;
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
	// Export MS Project upload file

	// ID;TaskID;Level;Outline;Name;Predecessors;StartDate;ExpireDate;CompleteDate;Resource
	if (type!=null && type.equals("export"))
	{
		// generate MS Project CSV file
		fname = "PRM_MSP_" + projIdS + "_" + dateS + ".csv"; // PRM_MSP_12345_06-10-04.txt

		//If objectId directory not exist, create it.
		subDirectory = new File(filePath);
		if(!subDirectory.exists())
			subDirectory.mkdirs();
		else
		{
			// need to remove the old summary file if they exist
			File [] flist = subDirectory.listFiles();
			String nameMatch = "Attachment-PRM_MSP_" + projIdS + "_";
			String s;
			for (int i=0; i<flist.length; i++)
			{
				if (flist[i].getName().startsWith(nameMatch))
				{
					// delete this file
					String fn = flist[i].getName();
					p.removeAttribute("Attachment", fn.substring(11, fn.length()));
					flist[i].delete();
				}
			}
		}

		filePath += File.separator + "Attachment-" + fname;
		f = new File(filePath);
		f.createNewFile();
		fos = new FileOutputStream(f);
		Date start, expire, complete;
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
		buf.append("ID;TaskID;Level;Outline;Name;Predecessors;StartDate;ExpireDate;CompleteDate;Resource");
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
		String[] levelInfo = new String[4];
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
					if (predecessors.length() > 0) predecessors = predecessors + ",";
					predecessors += iObj.toString();
				}
			}

			start = (Date)tk.getAttribute("CreatedDate")[0];
			expire = (Date)tk.getAttribute("ExpireDate")[0];
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
			buf.append(level+1); buf.append(DEL);
			buf.append(levelInfo[level]); buf.append(DEL);
			buf.append(pName); buf.append(DEL);
			buf.append(predecessors); buf.append(DEL);						// predecessors
			buf.append(Formatter.format(start)); buf.append(DEL);
			buf.append(Formatter.format(expire)); buf.append(DEL);
			if (complete != null)
				buf.append(Formatter.format(complete));
			buf.append(DEL);
			buf.append(empObj.getObjectName());
			buf.append(NL);
		}

		// save buffer to file
		fos.write(buf.toString().getBytes());
		fos.flush();
		fos.close();

		p.appendAttribute("Attachment", fname);
		p.setAttribute("LastUpdatedDate", new Date());
		pMgr.commit(p);

		response.sendRedirect("proj_profile.jsp?projId="+projIdS);	// default
		return;
	}

%>
