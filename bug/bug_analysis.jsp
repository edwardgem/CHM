<%@page import="java.awt.Font"%>
<%@page import="org.jfree.chart.title.TextTitle"%>
<%@ page contentType="text/html; charset=utf-8"%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<%
//
//	Copyright (c) 2007, EGI Technologies, Co.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File: bug_analysis.jsp
//	Author: ECC
//	Date:	09/05/07
//	Description: Graphical chart for bug analysis.
//	Modification:
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "util.*" %>
<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.omm.common.*" %>
<%@ page import = "oct.omm.client.*" %>
<%@ page import = "oct.omm.db.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "oct.util.general.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>
<%@ page import = "javax.activation.DataSource" %>

<%@ page import = "org.apache.log4j.Logger" %>
<%@ page import = "org.apache.soap.util.mime.ByteArrayDataSource" %>

<%@ page import = "org.jfree.chart.*" %>
<%@ page import = "org.jfree.chart.entity.StandardEntityCollection" %>
<%@ page import = "org.jfree.chart.ChartUtilities" %>
<%@ page import = "org.jfree.chart.JFreeChart" %>
<%@ page import = "org.jfree.data.general.DefaultPieDataset" %>
<%@ page import = "org.jfree.chart.servlet.*" %>
<%@ page import = "org.jfree.chart.plot.*" %>
<%@ page import = "org.jfree.data.category.CategoryDataset" %>
<%@ page import = "org.jfree.data.general.DatasetUtilities" %>
<%@ page import = "org.jfree.chart.axis.CategoryAxis" %>
<%@ page import = "org.jfree.chart.axis.CategoryLabelPositions" %>
<%@ page import = "org.jfree.chart.renderer.category.BarRenderer3D" %>
<%@ page import = "org.jfree.data.category.DefaultCategoryDataset" %>
<%@ page import = "org.jfree.chart.renderer.category.BarRenderer" %>
<%@ page import = "org.jfree.chart.labels.*" %>
<%@ page import = "org.jfree.ui.*" %>

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	String noSession = "../out.jsp?go=bug/bug_search.jsp";
%>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="<%=noSession%>" />

<%
	////////////////////////////////////////////////////////
	final int IMG_WIDTH		= 500;
	final int IMG_HEIGHT	= 300;
	final int TOTAL_CHARTS	= 5;
	
	final Font CHINESE_FONT = new Font("Song Ti", Font.BOLD, 16);

	if (pstuser instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?e=Access declined");
		return;
	}
	Logger l = PrmLog.getLog();

	SimpleDateFormat df = new SimpleDateFormat ("yyyy.MM.dd");

	int uid = pstuser.getObjectId();
	boolean isAdmin = false;
	int iRole = ((Integer)session.getAttribute("role")).intValue();
	if ( (iRole & user.iROLE_ADMIN) > 0 )
		isAdmin = true;

	bugManager bugMgr		= bugManager.getInstance();
	actionManager acMgr 	= actionManager.getInstance();
	userManager uMgr		= userManager.getInstance();
	projectManager pjMgr	= projectManager.getInstance();

	String projIdS = request.getParameter("projId");
	if (StringUtil.isNullOrEmptyString(projIdS)) {
		projIdS = (String) session.getAttribute("projId");
		if (StringUtil.isNullOrEmptyString(projIdS))
			projIdS = "0";		// no project selected
	}
	int selectedPjId = Integer.parseInt(projIdS);
	project selectedPj = null;
	try {selectedPj = (project)pjMgr.get(pstuser, selectedPjId);}
	catch (PmpException e)
	{
		// failed to get the project, go to select another project
		response.sendRedirect("../project/proj_select.jsp?backPage=../bug/bug_analysis.jsp");
		return;
	}

	String projName = selectedPj.getDisplayName();

	///////////////////////////////////////////////////////////////////////////////////////
	// bug report
	///////////////////////////////////////////////////////////////////////////////////////

	String filename0="", filename1="", filename2="", filename3="";
	String filename2a="";
	PrintWriter pw = new PrintWriter(out);
	ChartRenderingInfo info = new ChartRenderingInfo(new StandardEntityCollection());
	int [] ids;
	int ii, iOpen, iNew;
	int iTotal0 = 0;
	int cnt = 0;
	Date today = df.parse(df.format(new Date()));
	String lastWeek = df.format(new Date(today.getTime() - 86400000*7));

	String exprPj = "ProjectID='" + projIdS + "' ";

	ids = bugMgr.findId(pstuser, exprPj + "&& State='" + bug.ACTIVE
			+ "' && CreatedDate>'" + lastWeek + "'");
	iOpen = ids.length;
	ids = bugMgr.findId(pstuser, exprPj + "&& State='" + bug.OPEN
			+ "' && CreatedDate>'" + lastWeek + "'");
	iNew = ids.length; iTotal0 += iNew;


	///////////////////////////////////////////
	// 0. Total bug, filed last week, fixed last week
	String category = "";
	DefaultCategoryDataset dataset = new DefaultCategoryDataset();
	dataset.addValue(iOpen+iNew, "Total new/open", category);

	ids = bugMgr.findId(pstuser, exprPj
			+ "&& State!='" + bug.OPEN + "' && State!='" + bug.ACTIVE + "'"
			+ "&& CreatedDate>'" + lastWeek + "'"
			);
	dataset.addValue(ids.length, "Filed", category);

	ids = bugMgr.findId(pstuser, exprPj
			+ "&& CompleteDate>'" + lastWeek + "'"
			);
	dataset.addValue(ids.length, "Resolved", category);

	JFreeChart chart =
		ChartFactory.createBarChart3D(
	            "Bug Status Last Week on " + projName,      // chart title
	            "Last Week Status (since " + lastWeek + ")",               // domain axis label
	            "# of Bugs",                  // range axis label
	            dataset,                  // data
	            PlotOrientation.VERTICAL, // orientation
	            true,                     // include legend
	            true,                     // tooltips
	            false                     // urls
	        );

	TextTitle tt = chart.getTitle();
	tt.setFont(CHINESE_FONT);
	
	chart.setBackgroundPaint(java.awt.Color.white);
	CategoryPlot plot = chart.getCategoryPlot();
	CategoryAxis axis = plot.getDomainAxis();
	axis.setCategoryLabelPositions(
		CategoryLabelPositions.createUpRotationLabelPositions(Math.PI / 8.0)
		);
	BarRenderer3D renderer = (BarRenderer3D) plot.getRenderer();
	renderer.setDrawBarOutline(false);

	//
	//BarRenderer barRenderer = new BarRenderer();
	renderer.setItemLabelGenerator(new StandardCategoryItemLabelGenerator(
		StandardCategoryItemLabelGenerator.DEFAULT_LABEL_FORMAT_STRING,
		java.text.NumberFormat.getInstance()));
	renderer.setItemLabelsVisible(true);
	renderer.setItemMargin(0.10f);
	renderer.setPositiveItemLabelPosition(null);
	renderer.setSeriesPositiveItemLabelPosition(0,new ItemLabelPosition(ItemLabelAnchor.OUTSIDE12, TextAnchor.TOP_CENTER));
	renderer.setSeriesPositiveItemLabelPosition(1,new ItemLabelPosition(ItemLabelAnchor.OUTSIDE12,  TextAnchor.TOP_CENTER));
	renderer.setSeriesPositiveItemLabelPosition(2,new ItemLabelPosition(ItemLabelAnchor.OUTSIDE12,  TextAnchor.TOP_CENTER));
	//

	filename3 = ServletUtilities.saveChartAsPNG(chart, IMG_WIDTH, IMG_HEIGHT, info, session);
	//filename3 = ServletUtilities.saveChartAsJPEG(new File("C:chart.jpg"), chart, 500, 300);
	ChartUtilities.writeImageMap(pw, filename3, info, false);
	pw.flush();

	///////////////////////////////////////////
	// 1. bug status (new, active, fixed, closed)
	//DataSource [] dsArr = new DataSource[TOTAL_CHARTS];

	ids = bugMgr.findId(pstuser, exprPj + "&& State='" + bug.ACTIVE + "'");
	iOpen = ids.length;
	ids = bugMgr.findId(pstuser, exprPj + "&& State='" + bug.OPEN + "'");
	iNew = ids.length; iTotal0 += iNew;

	DefaultPieDataset pieDataset = new DefaultPieDataset();
	//ids = bugMgr.findId(pstuser, exprPj + "&& State='" + bug.ACTIVE + "'");
	iTotal0 += iOpen;
	pieDataset.setValue("Open", new Integer(iOpen));
	ids = bugMgr.findId(pstuser, exprPj
			+ "&& (State='" + bug.ANALYZED + "' || State='" + bug.FEEDBACK + "')");
	ii = ids.length; iTotal0 += ii;
	pieDataset.setValue("Fixed", new Integer(ii));
	ids = bugMgr.findId(pstuser, exprPj + "&& State='" + bug.CLOSE + "'");
	ii = ids.length; iTotal0 += ii;
	pieDataset.setValue("Closed", new Integer(ii));

	iTotal0 += iNew;
	pieDataset.setValue("New / Unassigned", new Integer(iNew));

	chart = ChartFactory.createPieChart
	                     ("Overall Bug Status on " + projName,	// Title
	                      pieDataset,           		// Dataset
	                      false,                 		// Show legend
	                      true,
	                      false
	                     );

	//PiePlot pie = new PiePlot(pieDataset);
	//pie.setExplodePercent(0, 0.30);
	//JFreeChart chart = new JFreeChart(pie);

	tt = chart.getTitle();
	tt.setFont(CHINESE_FONT);
	chart.setBackgroundPaint(java.awt.Color.white);

	//  Write the chart image to the temporary directory
	filename0 = ServletUtilities.saveChartAsPNG(chart, IMG_WIDTH, IMG_HEIGHT, info, session);

	//  Write the image map to the PrintWriter
	ChartUtilities.writeImageMap(pw, filename0, info, false);
	pw.flush();

	int iTotal1 = 0;
	int iTotal2 = 0, iDesign=0, iSW=0, iHW=0;
	if (iOpen > 0)
	{
		///////////////////////////////////////////
		// 2. open bug priority
		exprPj += "&& State='" + bug.ACTIVE + "' ";
		String [] val1 = {bug.PRI_HIGH+"%", bug.PRI_MED, bug.PRI_LOW};
		String [] label1 = {"High", "Medium", "Low"};
		pieDataset = new DefaultPieDataset();
		for (int m=0; m<val1.length; m++)
		{
			ids = bugMgr.findId(pstuser, exprPj + "&& Priority='" + val1[m] + "'");
			ii = ids.length; iTotal1 += ii;
			pieDataset.setValue(label1[m], new Integer(ii));
		}

		chart = ChartFactory.createPieChart
		                     ("Open Bug Priority (" + projName + ")",	// Title
		                      pieDataset,           		// Dataset
		                      false,                 		// Show legend
		                      true,
		                      false
		                     );
		
		tt = chart.getTitle();
		tt.setFont(CHINESE_FONT);

		chart.setBackgroundPaint(java.awt.Color.white);
		filename1 = ServletUtilities.saveChartAsPNG(chart, IMG_WIDTH, IMG_HEIGHT, info, session);
		ChartUtilities.writeImageMap(pw, filename1, info, false);

		///////////////////////////////////////////
		// 2a. open High Priority bug: different severity
		int iTotal2a = 0;
		String [] val1a = {bug.SEV_SCRUM, bug.SEV_CRI, bug.SEV_SER, bug.SEV_NCR};	// critical, serious, non-critical
		pieDataset = new DefaultPieDataset();
		String tempExec;
		for (int m=0; m<val1a.length; m++)
		{
			tempExec = exprPj + "&& Priority='" + bug.PRI_HIGH+"%'"
						+ " && Severity = '" + val1a[m] + "%'";	
			ids = bugMgr.findId(pstuser, tempExec);
			ii = ids.length; iTotal2a += ii;
			pieDataset.setValue(val1a[m], new Integer(ii));
		}

		chart = ChartFactory.createPieChart
		                     ("High Priority Open Bug Severity (" + projName + ")",	// Title
		                      pieDataset,           		// Dataset
		                      false,                 		// Show legend
		                      true,
		                      false
		                     );
		
		PiePlot plot1 = (PiePlot) chart.getPlot();
		plot1.setExplodePercent(0, 0.30);
		
		tt = chart.getTitle();
		tt.setFont(CHINESE_FONT);

		chart.setBackgroundPaint(java.awt.Color.white);
		filename2a = ServletUtilities.saveChartAsPNG(chart, IMG_WIDTH, IMG_HEIGHT, info, session);
		ChartUtilities.writeImageMap(pw, filename2a, info, false);

		///////////////////////////////////////////
		// 3. open bug type
		// CLASS_DS, CLASS_PS, CLASS_HW, CLASS_SW, CLASS_DOC, CLASS_SP
		String [] val2 = {bug.CLASS_DS, bug.CLASS_SW, bug.CLASS_HW, bug.CLASS_DOC, bug.CLASS_SP};
		String [] label2 = {"design", "sw-bug", "hw-bug", "doc-bug", "support"};
		pieDataset = new DefaultPieDataset();
		for (int m=0; m<val2.length; m++)
		{
			ids = bugMgr.findId(pstuser, exprPj + "&& Type='" + val2[m] + "'");
			ii = ids.length; iTotal2 += ii;
			if (ii>0 && m==0) iDesign=ii;
			else if (ii>0 && m==1) iSW = ii;
			else if (ii>0 && m==2) iHW = ii;
			pieDataset.setValue(label2[m], new Integer(ii));
		}
		ii = iTotal1 - iTotal2;
		if (ii > 0) pieDataset.setValue("others", new Integer(ii));

		chart = ChartFactory.createPieChart
		                     ("Open Bug Type (" + projName + ")",	// Title
		                      pieDataset,           		// Dataset
		                      false,                 		// Show legend
		                      true,
		                      false
		                     );
		
		tt = chart.getTitle();
		tt.setFont(CHINESE_FONT);

		chart.setBackgroundPaint(java.awt.Color.white);
		filename2 = ServletUtilities.saveChartAsPNG(chart, IMG_WIDTH, IMG_HEIGHT, info, session);
		ChartUtilities.writeImageMap(pw, filename2, info, false);
		pw.flush();
	}

	////////////////////////////////////////////////////////
%>


<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<link href="../oct-basic.css" rel="stylesheet" type="text/css" media="screen"/>
<link href="../oct-print.css" rel="stylesheet" type="text/css" media="print"/>
<jsp:include page="../init.jsp" flush="true"/>
<script type="text/javascript" src="../effect.js"></script>

<script language="JavaScript">
<!--

//-->
</script>


</head>

<title>CR Analysis</title>
<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" height="100%" border="0" cellspacing="0" cellpadding="0">
<tr>
	<td valign="top">
		<!-- Main Tables -->
		<table width="100%" border="0" cellspacing="0" cellpadding="0">
		  	<tr>
		    	<td width="100%" valign="top">
					<!-- Top -->
					<jsp:include page="../head.jsp" flush="true"/>
					<!-- End of Top -->
				</td>
			</tr>
			<tr>
	          <td>
	            <table width="100%" border="0" cellspacing="0" cellpadding="0">
				  <tr>
					<td width="26" height="30"><a name="top">&nbsp;</a></td>
                	<td height="30" align="left" valign="bottom" class="head">
					<b>Change Request Analysis Report</b>
					</td></tr>
	            </table>
	          </td>
	        </tr>
	</table>
	
<table width='90%' border='0' cellspacing='0' cellpadding='0'>	        
			<tr>
          		<td width="100%">
<!-- Navigation Menu -->
			<jsp:include page="<%=Prm.getTabFile()%>" flush="true">
				<jsp:param name="cat" value="Tracker" />
				<jsp:param name="subCat" value="CRAnalysis" />
				<jsp:param name="role" value="<%=iRole%>" />
			</jsp:include>
<!-- End of Navigation Menu -->
	        </tr>
		</table>
		<!-- Content Table -->

<table width="90%" border="0" cellspacing="0" cellpadding="0">

	<tr><td>
	<table width='100%' border='0' cellspacing='0' cellpadding='0'>
		<tr><td colspan="2">&nbsp;</td></tr>


<!-- Project Name -->
	<tr><td></td>
	<td>
<form>
	<table width="100%" border="0" cellpadding="0" cellspacing="0">
	<tr>
	<td class="heading" width='550'>
		Project Name:&nbsp;&nbsp;
		<select name="projId" class="formtext" onchange="submit()">
<%
	int [] projectObjId = pjMgr.getProjects(pstuser);
	if (projectObjId.length > 0)
	{
		PstAbstractObject [] projectObjList = pjMgr.get(pstuser, projectObjId);
		// @041906SWS
		Util.sortName(projectObjList, true);

		String pName;
		int pid;
		project pj;
		Date expDate;
		String expDateS = new String();
		for (int i=0; i < projectObjList.length ; i++)
		{
			// project
			pj = (project) projectObjList[i];
			pid = pj.getObjectId();;

			out.print("<option value='" + pid +"' ");
			if (pid == selectedPjId) {
				out.print("selected");
			}
			out.print(">" + pj.getDisplayName() + "</option>");
		}
	}
%>
		</select>

		&nbsp;&nbsp;
	</td>
	</tr>
	</table>
</form>
	</td>
	</tr>

		<tr><td colspan='2'><img src='../i/spacer.gif' width='1' height='30'/></td></tr>
		
		<tr>
			<td><img src='../i/spacer.gif' width='25' /></td>

<%	if (iTotal0 > 0)
	{
		String graphURL;

		graphURL = request.getContextPath() + "/servlet/DisplayChart?filename=" + filename3;
		out.print("<td><img src=" + graphURL + " width=500 height=300 border=0 usemap='#" + filename3 + "'></td>");
		out.print("</tr>");

		out.println("<tr><td colspan='2'><img src='../i/spacer.gif' height='30'/></td></tr>");
		out.print("<tr><td></td>");
		graphURL = request.getContextPath() + "/servlet/DisplayChart?filename=" + filename0;
		out.print("<td><img src=" + graphURL + " width=500 height=300 border=0 usemap='#" + filename0 + "'></td>");
		out.print("</tr>");

		if (iOpen > 0)
		{
			out.println("<tr><td colspan='2'><img src='../i/spacer.gif' height='30'></td></tr>");
			out.print("<tr><td></td>");
			graphURL = request.getContextPath() + "/servlet/DisplayChart?filename=" + filename1;
			out.print("<td><img src=" + graphURL + " width=500 height=300 border=0 usemap='#" + filename1 + "'></td>");
			out.print("</tr>");

			out.println("<tr><td colspan='2'><img src='../i/spacer.gif' height='30'/></td></tr>");
			out.print("<tr><td></td>");
			graphURL = request.getContextPath() + "/servlet/DisplayChart?filename=" + filename2a;
			out.print("<td><img src=" + graphURL + " width=500 height=300 border=0 usemap='#" + filename2a + "'></td>");
			out.print("</tr>");

			out.println("<tr><td colspan='2'><img src='../i/spacer.gif' height='30'></td></tr>");
			out.print("<tr><td></td>");
			graphURL = request.getContextPath() + "/servlet/DisplayChart?filename=" + filename2;
			out.print("<td><img src=" + graphURL + " width=500 height=300 border=0 usemap='#" + filename2 + "'></td>");
			out.print("</tr>");
		}
	}
	else
	{
		out.print("<td><span class='plaintext_big'><font color='#ee0000'>&nbsp;&nbsp;No bug filed</font></span></td>");
		out.print("</tr>");
	}
%>
	</table>
	</td></tr>

<tr>
	<td>
		<!-- Footer -->
		<jsp:include page="../foot.jsp" flush="true"/>
		<!-- End of Footer -->
	</td>
</tr>
</table>
</body>
</html>
