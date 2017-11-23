<%
//
//	Copyright (c) 2004-2005, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_delWF.jsp
//	Author: ECC
//	Date:		03/31/2004
//	Description:	Delete the checked flow instance and children: PstFlowStep, FlowData
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />


<%
	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("/error.jsp?msg=Access declined");
		return;
	}

	// get the list of PstFlow ids
	PstFlowManager fMgr = PstFlowManager.getInstance();
	PstFlowStepManager stepMgr = PstFlowStepManager.getInstance();
	FlowDataManager fdMgr = FlowDataManager.getInstance();
	planTaskManager ptMgr = planTaskManager.getInstance();
	planManager pMgr = planManager.getInstance();

	for (Enumeration e = request.getParameterNames() ; e.hasMoreElements() ;)
	{
		String temp = (String)e.nextElement();
		if (temp.startsWith("delete_"))
		{
			String flowId = temp.substring(7);
			PstFlow fObj = (PstFlow) fMgr.get(pstuser, flowId);

/*			// delete all the plan task associated to this flow
			String planIdS = (String)fObj.getAttribute("ContextObject")[0];
			int [] planTaskIds = ptMgr.findId(pstuser, "PlanID='" +planIdS+ "'");
			for (int i=0; i<planTaskIds.length; i++)
				ptMgr.delete(ptMgr.get(pstuser, planTaskIds[i]));

			// delete the plan
			pMgr.delete(pMgr.get(pstuser, planIdS));
*/
			// delete the PstFlowStep
			int [] stepId = stepMgr.findId(pstuser, "FlowInstanceName='" +fObj.getObjectName()+ "'");
			PstAbstractObject [] sObjList = stepMgr.get(pstuser, stepId);

			for (int i=0; i<sObjList.length; i++)
			{
				// get the FlowData object
				FlowData fdObj = (FlowData)fdMgr.get(pstuser, (String)sObjList[i].getAttribute("FlowDataInstance")[0]);
				fdMgr.delete(fdObj);			// delete flowdata
				stepMgr.delete(sObjList[i]);	// delete step instance
			}

			fMgr.delete(fObj);					// delete the flow instance
		}
	}

	response.sendRedirect("../admin/wf.jsp");

%>
