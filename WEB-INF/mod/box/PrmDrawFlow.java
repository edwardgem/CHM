//
//	Copyright (c) 2009 EGI Technologies Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
// $Header$
//
//	File:	$RCSfile$
//	Author:	ECC
//	Date:	12/26/2009
//
//	Modification:
//
/////////////////////////////////////////////////////////////////////
/**
* Display flow map
*/

package mod.box;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.StringReader;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;

import oct.codegen.task;
import oct.codegen.taskManager;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.pmp.exception.PmpException;
import oct.pmp.exception.PmpInternalException;
import oct.pmp.exception.PmpObjectNotFoundException;
import oct.pst.PstAbstractObject;
import oct.pst.PstFlow;
import oct.pst.PstFlowConstant;
import oct.pst.PstFlowDefManager;
import oct.pst.PstFlowManager;
import oct.pst.PstFlowStep;
import oct.pst.PstFlowStepManager;
import oct.pst.PstManager;
import oct.pst.PstUserAbstractObject;

import org.apache.log4j.Logger;

import util.Prm;
import util.PrmLog;
import util.Util;

public class PrmDrawFlow implements FlowBase
{
	private static final String NEWLINE		= "\n";
	private static final String INDENT		= "    ";
	private static final String EQ			= " = ";
	private static final String SEMICOLON	= ";";

	private static final String CON_VBOT= "conVbot";		// connector: vertical line 1/2 length
	private static final String CON_VTOP= "conVtop";		// connector: vertical line 1/2 length
	private static final String CON_V2	= "conV2";			// connector: vertical line

	private static Logger l = PrmLog.getLog();

	private static PstFlowManager fiMgr = null;
	private static PstFlowDefManager fdMgr = null;
	private static PstFlowStepManager fsMgr = null;
	private static userManager uMgr = null;
	private static taskManager tMgr = null;
	static user jwu = Prm.getSpecialUser();

	static {
		try {
			fiMgr = PstFlowManager.getInstance();
			fdMgr = PstFlowDefManager.getInstance();
			fsMgr = PstFlowStepManager.getInstance();
			uMgr = userManager.getInstance();
			tMgr = taskManager.getInstance();
		}
		catch (PmpException e){}
	}


	/**
	  * take a flow class and return an HTML String for display of the flow
	  * @param fObj the Java flow object to be display in HTML
	  */
	public static String getFlowDisplayHTML(Flow fObj)
	{
		// first find out the estimated size of the table
		fObj.setLevel();

		// for testing, print out the flow
		//System.out.println(fObj.toString());

		// after setLevel() all steps have the tightest levels set up, now create space for connect lines
		// find overlaps and expand table rows, and put all drawing info into a table
		Object [][] table = fObj.fixOverlap();
		int tabRow = table.length;
		int tabCol = table[0].length;

		// after fixOverlap() I have all the info in table[][] to create HTML
		String bgColor;				// bgcolor for step status
		StringBuffer sBuf = new StringBuffer(8192);
		sBuf.append("<table border='0' cellspacing='0' cellpadding='0'>");
		for (int i=0; i<tabRow; i++)
		{
			//System.out.println(">>> row " + i);
			sBuf.append("<tr>");			// a new row
			Object obj;
			for (int j=0; j<tabCol; j++)
			{
				obj = table[i][j];
				//System.out.print("(" + i + ", " + j + ") = ");
				if (obj == null) {
					//System.out.println("null");
					sBuf.append("<td></td>");
				}
				else if (obj instanceof Step)
				{				
					// step
					// a table composed of 4 cells: arrowHead, status cell, step icon, arrowTail
					Step step = (Step)obj;
					bgColor = ((Step)obj).getColor();	// will get real-time state to find color
					sBuf.append("<td><table border='0' cellspacing='0' cellpadding='0'><tr>");
					if (j == 0)
					{
						// initial step (only one, specially added)
						//System.out.println("head step: " + step.getName());
						sBuf.append("<td><table><tr>");
						//sBuf.append("<td>" + addEmptyArrowSpace() + "</td>");
						sBuf.append("<td class='sysSd'>Start</td>");
						//sBuf.append("<td><img src='../box/i/arrowHead.gif'/></td>");
						//drawStepBox(sBuf, step, bgColor);
						sBuf.append("</tr></table></td>");
						sBuf.append("<td><img src='../box/i/arrowTail.gif'/></td>");
					}
					else if (step.getOutStep().size() <= 0)
					{
						// ending step (only one, specially added)
						//System.out.println("end step: " + step.getName());
						sBuf.append("<td><img src='../box/i/arrowHead.gif'/></td>");
						sBuf.append("<td><table><tr>");
						//drawStepBox(sBuf, step, bgColor);
						//sBuf.append("<td>" + addEmptyArrowSpace() + "</td>");
						//sBuf.append("<td><img src='../box/i/arrowTail.gif'/></td>");
						sBuf.append("<td class='sysSd'>End</td>");
						sBuf.append("</tr></table></td>");
					}
					else
					{
						// in-between step
						//System.out.println("step: " + step.getName());
						sBuf.append("<td><img src='../box/i/arrowHead.gif'/></td>");
						drawStepBox(sBuf, step, bgColor);
						sBuf.append("<td><img src='../box/i/arrowTail.gif'/></td>");
					}
					sBuf.append("</tr></table></td>");
				}
				else if (obj instanceof String)
				{
					// connector or step name
					//System.out.println("others: " + obj.toString());
					if (obj.equals(CON_VBOT))
						sBuf.append("<td valign='bottom'><img src='../box/i/conV.gif' /></td>");
					else if (obj.equals(CON_VTOP))
						sBuf.append("<td valign='top'><img src='../box/i/conV.gif' /></td>");
					else if (obj.equals(CON_V2))
						sBuf.append("<td height='100%'><img height='100%' width='2' src='../box/i/conV2.gif' /></td>");
					else {
						sBuf.append("<td></td>");
						//sBuf.append("<td class='sd'>" + obj + "</td>");	// step name
					}
				}
			}
			sBuf.append("</tr>");			// close a row
		}
		sBuf.append("</table>");

		return sBuf.toString();
	}	// END: getFlowDisplayHTML()

	private static void drawStepBox(StringBuffer sBuf, Step step, String bgColor)
	{
		sBuf.append("<td><table border='0' cellspacing='0' cellpadding='2'>");
		sBuf.append("<tr bgcolor='" + bgColor + "'>");
		//sBuf.append(step.getPrefixBoxContent());
		sBuf.append("<td class='sd' id='step_" + step.getId() + "' "
				+ "onclick='onClickStep(" + step.getId() + ");'"
				+ "ondblclick='onDblClickStep(" + step.getId() + ");'"
				+ ">" + step.getName() + "</td>");
		sBuf.append("</tr></table></td>");
	}

	// convenient method
	// first assume the flowId/flowName is a flow instance, if not, check flow definition
	public static Flow parseXMLtoFlow(PstUserAbstractObject pstuser, String flowName, Boolean bSelect)
		throws PmpException
	{
		return parseXMLtoFlow(pstuser, flowName, bSelect, null);
	}
	/**
	 * parseXMLtoFlow
	 * @param pstuser
	 * @param flowName
	 * @param bSelect
	 * @param bGetFromDraft
	 * @return
	 * @throws PmpException
	 */
	public static Flow parseXMLtoFlow(
			PstUserAbstractObject pstuser,
			String flowName,
			Boolean bSelect,
			Boolean bGetFromDraft)
		throws PmpException
	{
		PstAbstractObject flow = null;
		Object content = null;
		String attName, type=null;
		if (bGetFromDraft == null)
			bGetFromDraft = new Boolean(false);
		if (bGetFromDraft)
			attName = "Draft";			// try get from draft first
		else
			attName = "Content";

		try
		{
			flow = fiMgr.get(pstuser, flowName);		// instance
			content = flow.getAttribute(attName)[0];
			type = FlowBase.TYPE_INSTANCE;
		}
		catch (PmpException e) {}
		if (flow==null)
		{
			flow = fdMgr.get(pstuser, flowName);		// definition
			content = flow.getAttribute(attName)[0];
			type = FlowBase.TYPE_DEFINITION;
		}
		if (bGetFromDraft && flow!=null && Util.isEmptyRaw(content))
		{
			// try get from draft but is empty, get from Content now
			content = flow.getAttribute("Content")[0];
		}
		if (Util.isEmptyRaw(content)) return null;
		Flow fObj = parseXMLtoFlow(pstuser, content, bSelect);
		if (fObj != null)
			fObj.setType(type);
		return fObj;
	}
	// convenient method
	public static Flow parseXMLtoFlow(PstUserAbstractObject pstuser, int flowId, Boolean bSelect)
		throws PmpException
{
	return parseXMLtoFlow(pstuser, flowId, bSelect, null);
}
	public static Flow parseXMLtoFlow(
			PstUserAbstractObject pstuser, int flowId, Boolean bSelect, Boolean bGetFromDraft)
		throws PmpException
	{
		PstAbstractObject flow = null;
		Object content = null;
		String attName, type=null;
		if (bGetFromDraft == null)
			bGetFromDraft = new Boolean(false);
		if (bGetFromDraft)
			attName = "Draft";			// try get from draft first
		else
			attName = "Content";

		try
		{
			flow = fiMgr.get(pstuser, flowId);			// instance
			content = flow.getAttribute(attName)[0];
			if (content == null) {
				// I found the flow instance object but there is no content
				// try to get it from its corresponding flow definition
				String flowDefName = (String) flow.getAttribute(PstFlow.ATTR_FLOWDEF_NAME)[0];
				if (flowDefName == null)
					return null;		// no flow definition: possibly project flow

				PstAbstractObject fd = fdMgr.get(pstuser, flowDefName);
				if (fd != null) {
					content = fd.getAttribute("Content")[0];
					if (content != null) {
						flow.setAttribute("Content", content);
						fiMgr.commit(flow);		// save a copy from flow definition
					}
				}
			}
			type = FlowBase.TYPE_INSTANCE;
System.out.println("parseXMLtoFlow() got flow instance " + flowId);
		}
		catch (PmpException e) {}
		if (flow==null)
		{
			flow = fdMgr.get(pstuser, flowId);			// definition
			content = flow.getAttribute(attName)[0];
			type = FlowBase.TYPE_DEFINITION;
		}
		if (bGetFromDraft && flow!=null && Util.isEmptyRaw(content))
		{
			// try get from draft but is empty, get from Content now
			content = flow.getAttribute("Content")[0];
		}
		if (Util.isEmptyRaw(content)) return null;
		Flow fObj = parseXMLtoFlow(pstuser, content, bSelect);
		if (fObj != null)
			fObj.setType(type);
		return fObj;
	}

	/**
	  * parse an XML to create a flow object
	  * @param pstuser PST user of the current connected session
	  * @param textObj the attribute Content object of the flow instance or definition
	  * @param bSelect put radio select box in steps that can be selected for change
	 * @throws PmpException
	 * @throws PmpInternalException
	 * @throws PmpObjectNotFoundException
	  */
	private static Flow parseXMLtoFlow(
			PstUserAbstractObject pstuser, Object textObj, Boolean bSelect)
		throws PmpException
	{
		// get the flow XML from DB
		String flowXML = (textObj==null?null:new String((byte[])textObj));
		if (flowXML==null || flowXML.length()<=0)
			return null;

		BufferedReader bis = new BufferedReader(new StringReader(flowXML));
		String flowName = getFlowName(bis);
		Flow resFlow = null;
		HashMap <String,Step> stepMap = null;
		Step stepObj;

		stepObj = new Step("Begin");
		stepObj.setId(Step.BEGIN_STEP_ID);
		Step beginStep = stepObj;
		
		if (resFlow == null) {
			resFlow = new Flow(flowName);
			resFlow.setFirstStep(beginStep);		// always have one beginning step
			stepMap = resFlow.getStepMap();
		}
		
		// put a beginning step to the stepMap
		stepMap.put(Step.BEGIN_STEP_ID, beginStep);
		
		// put an ending step to the stepMap
		stepObj = new Step("End");
		stepObj.setId(Step.END_STEP_ID);
		Step endStep = stepObj;
		stepMap.put(Step.END_STEP_ID, endStep);
		
		// after this point all is left in the XML is Step and Data sections

		Object tagObj;
		String stepIdS;
		while ((tagObj = parseNextTag(bis)) != null)
		{
			//System.out.println("parseXMLtoFlow() got next step = "+stepObj);
			if (!(tagObj instanceof Step)) {
				// it must be data section
				if (resFlow != null) {
					resFlow.setDataMap(tagObj);
				}
				else {
					l.error("parseXMLtoFlow() fails to find flowObject when setting dataMap.");
				}
				continue;
			}

			stepObj = (Step)tagObj;

			if (bSelect!=null && bSelect)
				stepObj.setSelect();			// set select option based on step state

			stepObj.setFlow(resFlow);			// remember the flow object the step belongs to

			// put step in hash map
			stepIdS = stepObj.getId();
			stepMap.put(stepIdS, stepObj);
			resFlow.setNextStepIdIfNeeded(stepIdS);	// set the next ID value to be used by new steps
			
			// if it is a begin step, make it comes from the default beginning step
			if (stepObj.getInToken() <= 0) {
				stepObj._inStepArr.add(Step.BEGIN_STEP_ID);
				beginStep._outStepArr.add(stepIdS);
				// after this, stepObj.isBeginStep() will be false
			}
			
			// if it is an end step, make it points to default ending step
			if (stepObj.isEndStep()) {
				stepObj._outStepArr.add(Step.END_STEP_ID);
				endStep._inStepArr.add(stepIdS);
			}
		}

		// connect the steps together
		if (resFlow != null) {
			resFlow.getFirstStep().setChildrenLink(stepMap);
		}

		return resFlow;


	}	// END: parseXMLtoFlow()

	private static final String begStepTag = PstFlowConstant.BEG_STEP_TAG;
	private static final String begDataTag = PstFlowConstant.BEG_DATA_TAG;
	private static final String endTag = PstFlowConstant.END_TAG;
	private static final int tagLen = begStepTag.length();

	/**
	  * parse tags within the flow: either STEP or DATA
	  * start read from the current pos of input stream, extra the next step object
	  * or data object
	  */
	public static Object parseNextTag(BufferedReader din)
	{
		// read the next tag from input stream
		try
		{
			String line, res = "";
			boolean bFound = false;		// found <step or <data
			int idx;
			boolean isStep = false;		// either step or data

			while ((line = din.readLine()) != null)
			{
				line = line.trim();
				if ((line.length() <= 0) || (line.charAt(0) == '#'))
					continue;						// comment line and blank line
				
				// ECC: ******
System.out.println(">>>>>>>>>>>>>>>>>>>>> line: " + line);						
				if (line.contains("</flow>")) {
					System.out.println("********** found </flow>");
					return null;
				}

				if (bFound
					|| (line.length()>=tagLen && line.substring(0,tagLen).equalsIgnoreCase(begStepTag))
					|| (line.length()>=tagLen && line.substring(0,tagLen).equalsIgnoreCase(begDataTag))
					)
				{
					if (!bFound)
					{
						// just found the "<step" or "<data" tag, start extracting multiple lines
						// begin tag, might have some content, need to extract the rest of the line
						bFound = true;
						isStep = line.substring(0,tagLen).equalsIgnoreCase(begStepTag);

						line = line.substring(tagLen);
						if (line.length() <= 0)
							continue;			// only has begin step tag and nothing behind

						if ((idx = line.indexOf(endTag)) != -1)
						{
							// found end /> tag, extract content and done
							res = line.substring(0, idx).trim();
							break;			// done
						}
						else
						{
							// no end tag, just return the rest of the line which might have step attribute
							res = line;
						}
					}
					else
					{
						// it is extracting attribute lines after <step or <data tag
						if ((idx = line.indexOf(endTag)) != -1)
						{
							// found end /> tag
							if (idx > 0)
							{
								// more content before the end tag
								res += line.substring(0, idx);
							}
							break;		// done with extracting one step
						}
						else
						{
							// a content line, just extract
							res += line;
						}
					}
				}
			}	// END: while loop

			if (!bFound)
				return null;

			// now res contains the step or data String separated by ";"
			Object resObj;
			if (isStep) {
				resObj = constructStep(res);	// res already stripped beg and end tags
			}
			else {
				resObj = constructDataMap(res);	// resObj is a hashMap
			}
			return resObj;
		}
		catch (IOException e) {return null;}
	}	// END: getNextStep()

	/**
	  * Take a string and return a Step object
	  */
	private static Step constructStep(String str)
	{
		// str is a string of attributes separated by ";"

		// now start extracting attributes
		String [] sa = getKeyValueArray(str);
		String [] sa1;
		String key, val;

		Step stepObj = new Step();
		PstFlowStep existStep = null;

		for (int i=0; i<sa.length; i++)
		{
			sa1 = sa[i].split("=");
			if (sa1.length != 2)
			{
				l.error("PrmDrawFlow.constructStep(): Wrong number of parameter on step attribute line.\n"
						+ "   " + sa[i]);
				continue;
			}

			// get and set attributes
			key = sa1[0].trim();
			val = sa1[1].trim();
			if (val.charAt(0)=='"' && val.charAt(val.length()-1)=='"') {
				// trim double quotes
				val = val.substring(1, val.length()-1);
			}

			if (key.equalsIgnoreCase(ID)) {
				stepObj.setId(val);
			}
			else if (key.equalsIgnoreCase(NAME)) {
				stepObj.setName(val);
			}
			else if (key.equalsIgnoreCase(STATE)) {
				stepObj.setState(val);
			}
			else if (key.equalsIgnoreCase(TASKID)) {
				stepObj.setTaskId(val);
				
				// if the task has a step associated, we must get the step attributes
				// from there to have the real-time info of the step
				try {
					task tObj = (task) tMgr.get(jwu, val);
					stepObj.setTaskState(tObj.getState());
					existStep = tObj.getStep(jwu);
				} catch (PmpException e) {/*no step: ignore*/}
			}
			else if (key.equalsIgnoreCase(TASK_STATE)) {
				stepObj.setTaskState(val);
			}
			else if (key.equalsIgnoreCase(CREATED)) {
				Date dt = null;
				try {dt = Step.df.parse(val);}
				catch (ParseException e) {}
				stepObj.setCreatedDate(dt);
			}
			else if (key.equalsIgnoreCase(EXPIRE)) {
				Date dt = null;
				try {dt = Step.df.parse(val);}
				catch (ParseException e) {}
				stepObj.setExpireDate(dt);
			}
			else if (key.equalsIgnoreCase(CREATOR)) {
				stepObj.setCreator(val);
			}
			else if (key.equalsIgnoreCase(ASSIGN)) {
				stepObj.setAssignTo(val);
			}
			else if (key.equalsIgnoreCase(WORKBY)) {
				stepObj.setWorkBy(val);
			}
			else if (key.equalsIgnoreCase(INTOKEN)) {
				// make sure it is an integer
				int token;
				try {token = Integer.parseInt(val);}
				catch (Exception e)
				{
					l.error("INTOKEN must be an integer value.\n"
							+ "   " + sa[i]);
					return null;
				}

				stepObj.setInToken(token);
			}
			else if (key.equalsIgnoreCase(OUTSTEP)) {
				stepObj.setOutStep(val);
			}
		}
		
		// get real-time info from current step if it existed
		try {
			if (existStep != null) {
				// CurrentExecutor, CreatedDate, State, OutgoingStepInstance(M)
				stepObj.setWorkBy((String)existStep.getAttribute("CurrentExecutor")[0]);
				stepObj.setCreatedDate((Date)existStep.getAttribute("CreatedDate")[0]);
				stepObj.setState((String)existStep.getAttribute("State")[0]);
			}
		} catch (PmpException e) {}

		return stepObj;
	}	// END: constructStep()


	/**
	  * Take a string and return a HashMap containing the data pairs
	  */
	private static HashMap<String,String> constructDataMap(String str)
	{
		// str is a string of attributes separated by ";"
System.out.println("parsing datamap");

		// now start extracting attributes
		String [] sa = getKeyValueArray(str);
		String [] sa1;
		String fieldLabel, attrName;

		HashMap<String,String> dataMap = new HashMap<String,String>();

		for (int i=0; i<sa.length; i++)
		{
			sa1 = sa[i].split("=");
			if (sa1.length != 2)
			{
				l.error("Wrong number of parameter on data map line.\n"
						+ "   " + sa[i]);
				continue;
			}
			fieldLabel = sa1[0].trim();	// field label
			attrName = sa1[1].trim();	// omm attribute name
System.out.println("found data pair (" + fieldLabel + ", " + attrName + ")");
			dataMap.put(fieldLabel, attrName);
		}
		return dataMap;
	}

	private static String [] getKeyValueArray(String str)
	{
		// str is a string of attributes separated by ";"
		if (str==null || str.length()<=0)
			return null;

		str = str.trim();

		// strip begin tag if present
		if (str.startsWith(begStepTag)) {
			str = str.substring(begStepTag.length()).trim();
		}
		else if (str.startsWith(begDataTag)) {
			str = str.substring(begDataTag.length()).trim();
		}

		// strip end tag if present
		if (str.endsWith(endTag))
		{
			str = str.substring(0, str.length()-endTag.length()).trim();
		}

		// now start extracting attributes
		String [] sa = str.split(";");

		return sa;
	}

	private static String begFlowTag = "<flow";
	private static String endFlowTag = "</flow>";
	private static String getFlowName(BufferedReader din)
	{
		// "<flow name=testFlow>"
		String flowName = null;
		String line, lowercaseLine;

		try {
			while ((line = din.readLine()) != null)
			{
				line = line.trim();
				lowercaseLine = line.toLowerCase();
				if ((line.length() <= 0) || (line.charAt(0) == '#'))
					continue;						// comment line and blank line

				if (lowercaseLine.startsWith(begFlowTag))
				{
					// the name tag is following the <flow tag
					flowName = line.substring(begFlowTag.length()).trim();
					int len = flowName.length();
					if (flowName.charAt(len-1) == '>')
					{
						// remove "name=" and ending ">"
						flowName = flowName.substring(flowName.indexOf('=')+1, len-1).trim();
					}
					break;
				}
			}
		} catch (IOException e) {
			l.error("Got IOException at getFlowName().");
			e.printStackTrace();
		}
		return flowName;
	}	// END: getFlowName()

	// check to see if a row in the table is all null (empty)
	private static boolean emptyRow(Object [][] table, int row)
	{
		for (int j=0; j<table[0].length; j++)
			if (table[row][j] != null)
				return false;
		return true;
	}

	private static String addEmptyArrowSpace()
	{
		return "<table border='0' cellspacing='0' cellpadding='0'>"
			+ "<tr><td><img src='../i/spacer.gif' width='40'/></td></tr></table>";
	}

	/**
	 * Take a new step object and add it to the Draft (XML) of the flow object
	 * @param u
	 * @param flowId
	 * @param stepObj
	 * @throws PmpException
	 * @throws
	 */
	public static void addStepToFlow(PstUserAbstractObject u, String flowIdS, Step newStepObj)
		throws PmpException
	{
		// get original flow object from Draft if exist
		Flow fObj = parseXMLtoFlow(u, Integer.parseInt(flowIdS), null, new Boolean(true));

		// get the next temp ID from flow object and store it in hash
		newStepObj.setId(String.valueOf(fObj.getSetNextStepId()));
		fObj.getStepMap().put(newStepObj.getId(), newStepObj);

		if (newStepObj.getInStep().size() > 0)
		{
			// insert after an existing step
			Step parent = fObj.getStep(newStepObj.getInStep().get(0));
			newStepObj._outStepArr = parent.getOutStep();	// parent's outsteps are mine now
			newStepObj._childArr = parent._childArr;
			for (int i=0; i<newStepObj._childArr.size(); i++)
			{
				Step aStep = newStepObj._childArr.get(i);
				aStep.replaceParent(parent.getId(), null);
				aStep.addParent(newStepObj.getId());
			}
			parent.setNewChild(newStepObj);
		}
		else if (newStepObj.getOutStep().size() > 0)
		{
			// insert before an existing step
			// ECC TODO
		}

		// set step values
		newStepObj.setFlow(fObj);
		newStepObj.setCreatedDate(new Date());

		// put the update flow object to the draft XML
		fObj.saveXMLtoDraft(u, flowIdS);
	}

	/**
	 * Delete a step from the draft XML flow
	 * @param u
	 * @param flowIdS
	 * @param stepIdS
	 */
	public static void delStepFromFlow(PstUserAbstractObject u, String flowIdS, String stepIdS)
		throws PmpException
	{
		// get original flow object from Draft if exist
		Flow fObj = parseXMLtoFlow(u, Integer.parseInt(flowIdS), null, new Boolean(true));
		HashMap <String, Step> stepMap = fObj.getStepMap();
		Step delStepObj = stepMap.remove(stepIdS);
		ArrayList <String> inArr = delStepObj.getInStep();
		ArrayList <String> outArr = delStepObj.getOutStep();
		for (int i=0; i<inArr.size(); i++)
		{
			// all my parents need to change children
			Step parent = stepMap.get(inArr.get(i));
			parent.replaceChildren(stepIdS, outArr, stepMap);
		}
		for (int i=0; i<outArr.size(); i++)
		{
			// all my children need to change parent
			Step child = stepMap.get(outArr.get(i));
			child.replaceParent(stepIdS, inArr);
		}

		// put the update flow object to the draft XML
		fObj.saveXMLtoDraft(u, flowIdS);
	}

	/**
	  *********************************************************
	  * Flow class
	  */

	public static class Flow
	{
		String _type;			// instance or definition
		String _name;
		Step _firstStep;
		int _bottom, _right;	// left is always 0
		HashMap <String,Step> _stepMap;
		HashMap <String,String> _dataMap;
		int _nextStepId;		// the temp ID to use when adding a new step

		Flow(String name)
		{
			_type = null;
			_name = name;
			_bottom = _right = 0;
			_stepMap = new HashMap<String, Step>();
			_dataMap = new HashMap<String, String>();
			_nextStepId = 1;	// a monotonically increasing stepID to be used when adding new step
		}

		private void setType(String type) {_type = type;}
		public String getType() {return _type;}
		public String getName() {return _name;}
		public Step getFirstStep() {return _firstStep;}				// a special step
		public void setFirstStep(Step step) {_firstStep = step;}
		public HashMap <String,Step> getStepMap() {return _stepMap;}
		public HashMap <String,String> getDataMap() {return _dataMap;}
		private void setDataMap(Object map) {_dataMap = (HashMap)map;}

		public void setLevel()
		{
			if (_firstStep == null) return;
			_firstStep.setLevel(-1, 0, this);	// parentLevel, myLevel, parentFlow
		}

		public Object [][] fixOverlap()
		{
			if (_firstStep == null) return null;

			// first fill the 2D table with init step info
			int row = (_bottom + 1) * 2;		// estimate with caption and overlap
			int col = 2 * (_right+1) - 1;		// this should be accurate
System.out.println("flow.fixOverlap() row=" + row + ", col=" + col);

			Object [][] table = new Object[row][col];
			for (int i=0; i<row; i++)
				for (int j=0; j<col; j++)
					table[i][j] = null;

			table = _firstStep.fixOverlap(0, 0, table);
			return table;
		}

		public String toString()
		{
			StringBuffer sBuf = new StringBuffer();
			sBuf.append(begFlowTag + " ");
			sBuf.append(NAME + EQ + getName() + ">" + NEWLINE);
			Step aStep = this._firstStep;
			if (aStep != null) {
				// it will recursively get all steps
				sBuf.append(aStep.toString() + NEWLINE);
			}

			// data
			sBuf.append(begDataTag + NEWLINE);
			for (String key: _dataMap.keySet()) {
				sBuf.append(INDENT + key + EQ + _dataMap.get(key) + SEMICOLON + NEWLINE);
			}
			sBuf.append(endTag + NEWLINE);

			sBuf.append(endFlowTag + NEWLINE);

			return sBuf.toString();
		}

		public Step getStep(String stepId)
		{
			return _stepMap.get(stepId);
		}

		public int getNextStepId() {return _nextStepId;}
		public int getSetNextStepId() {return _nextStepId++;}
		public void setNextStepId(int id) {_nextStepId = id;}
		public void setNextStepIdIfNeeded(String idS)
		{
			if (idS == null) return;
			int id = Integer.parseInt(idS);
			if (id<1000 && id>=_nextStepId)
				setNextStepId(id+1);				// I want to inc (set) the next ID
		}
		
		/**
		 * pack all the step info into a string (used by Javascript)
		 */
		public String getStepInfoString()
		{
			// stepID | attrName::info | ... @@<another step> ...
			StringBuffer sBuf = new StringBuffer(4096);
			String delim1 = "|";
			String delim2 = "::";
			
			String s;
			PstAbstractObject o;
			
			HashMap<String,Step> stepMap = getStepMap();
			for (String stepId: stepMap.keySet()) {
				if (Integer.parseInt(stepId) < 0)
					continue;		// begin and end steps
				Step aStep = stepMap.get(stepId);
				
				// put the step info in the buffer
				sBuf.append(stepId);
				sBuf.append(delim1 + NAME + delim2 + aStep.getName());
				sBuf.append(delim1 + TASKID + delim2 + aStep.getTaskId());

				sBuf.append(delim1 + "Task State" + delim2 + aStep.getTaskState());
				s = aStep.getStateString();				
				if (!Util.isNullOrEmptyString(s))
					sBuf.append(delim1 + "Step State" + delim2 + Character.toUpperCase(s.charAt(0)) + s.substring(1));

				sBuf.append(delim1 + CREATED + delim2 + aStep.getCreatedDateString());
				sBuf.append(delim1 + EXPIRE + delim2 + aStep.getExpireDateString());
				
				sBuf.append(delim1 + CREATOR + delim2 + user.getFullName(jwu, aStep.getCreator()));
				sBuf.append(delim1 + ASSIGN + delim2 + user.getFullName(jwu, aStep.getAssignTo()));

				sBuf.append(delim1 + WORKBY + delim2 + user.getFullName(jwu, aStep.getWorkBy()));
				sBuf.append(delim1 + INTOKEN + delim2 + aStep.getInToken());
				sBuf.append("@@");	// separate for next step
			}
			return sBuf.toString();
		}

		private PstManager getPstManager()
		{
			if (this.getType().equals(FlowBase.TYPE_INSTANCE))
				return fiMgr;
			else
				return fdMgr;
		}

		private void saveXMLtoDraft(PstUserAbstractObject u, String flowIdS)
			throws PmpException
		{
			String flowXML = this.toString();
			PstManager mgr = this.getPstManager();
			PstAbstractObject pstFlowObj = mgr.get(u, Integer.parseInt(flowIdS));
			pstFlowObj.setAttribute("Draft", flowXML.getBytes());
			mgr.commit(pstFlowObj);
			l.info("Saved draft of flow " + getType() + " [" + pstFlowObj.getObjectId() + "]");
		}
	}	// END: Flow class



	/**
	  **********************************************************************************
	  * Step class
	  **********************************************************************************
	  */
	public static class Step
	{
		// private
		public static final SimpleDateFormat df = new SimpleDateFormat ("MM/dd/yyyy");

		// constants
		public final static String [] ST_ARRAY	= {"",
			PstFlowConstant.ST_STEP_NEW,
			PstFlowConstant.ST_STEP_ACTIVE,
			PstFlowConstant.ST_STEP_COMMIT,
			PstFlowConstant.ST_STEP_ABORT};

		public final static int ST_NULL			= 0;
		public final static int ST_NEW			= 1;
		public final static int ST_ACTIVE		= 2;
		public final static int ST_COMMIT		= 3;
		public final static int ST_ABORT		= 4;

		public final static String TYPE_BEGIN		= "begin";
		public final static String TYPE_END			= "end";
		public final static String TYPE_INBETWEEN	= "inbetween";
		
		public final static String BEGIN_STEP_ID	= "-1";
		public final static String END_STEP_ID		= "-2";

		public final static String NEW_NAME		= "new task";	// append a digit


		// members
		String _name;
		String _id;
		String _taskId;
		String _taskState;
		String _creator;
		String _assign;
		String _workBy;
		int _inToken;
		ArrayList <String> _inStepArr;			// parents		(for drawing only)
		ArrayList <String> _outStepArr;			// children (ID String)
		ArrayList <Step> _childArr;				// children (actual Step object)
		int _levelH, _levelV;					// (for drawing only)
		boolean _bInTable;						// (for drawing only)
		int _state;								// ECC: do I need this?
		boolean _selectOption;					// prefix the step with a radio box
		Flow _flow;								// the flow this step belongs to
		Date _createdDt;
		Date _expireDt;

		public Step()
		{
			_outStepArr = new ArrayList<String>();
			_inStepArr = new ArrayList<String>();
			_childArr  = new ArrayList<Step>();
			_levelH = _levelV = 0;
			_bInTable = false;
			_state = ST_NULL;
			_selectOption = false;
			_creator = "";
			_assign = "";
			_workBy = "";
			_inToken = 0;
			_taskId = "";
			_taskState = "";
		}
		public Step(String name)
		{
			this();
			_name = name;
		}

		public String getId() {return _id;}
		public String getName() {return _name;}
		public String getCreator() {return _creator;}
		public String getAssignTo() {return _assign;}
		public String getWorkBy() {return _workBy;}
		public int getInToken() {return _inToken;}
		public ArrayList <String> getOutStep() {return _outStepArr;}
		public ArrayList <String> getInStep() {return _inStepArr;}
		public ArrayList <Step> getChildren() {return _childArr;}
		public void setFlow(Flow fObj) {_flow = fObj;}
		public Flow getFlow() {return _flow;}
		public void setState(String s) {_state = getStateInt(s);}
		public void setState(int iState) {_state = iState;}
		public int getState() {return _state;}
		public String getStateString() {return ST_ARRAY[_state];}

		private int getStateInt(String s) {
			for (int i=0; i<ST_ARRAY.length; i++)
				if (ST_ARRAY[i].equalsIgnoreCase(s))
					return i;
			return 0;
		}

		public void setTaskId(String tidS) {_taskId = tidS;}
		public String getTaskId() {return _taskId;}
		public void setTaskState(String st) {_taskState = st;}
		public String getTaskState() {return _taskState;}
		public void setCreatedDate(Date dt) {_createdDt = dt;}
		public Date getCreatedDate() {return _createdDt;}
		public String getCreatedDateString() {return _createdDt==null?"":df.format(_createdDt);}
		public void setExpireDate(Date dt) {_expireDt = dt;}
		public Date getExpireDate() {return _expireDt;}
		public String getExpireDateString() {return _expireDt==null?"":df.format(_expireDt);}

		private boolean hasMultiParent() {return (_inStepArr.size()>1);}
		private boolean isFirstParent(Step aStep)
		{
			if (_inStepArr.size() <= 0) return false;	// if no parent
			if (_inStepArr.get(0).equals(aStep.getId()))
				return true;
			return false;
		}
		private boolean isLastParent(Step aStep)
		{
			if (_inStepArr.size() <= 1) return false;	// if no or single parent
			if (_inStepArr.get(_inStepArr.size()-1).equals(aStep.getId()))
				return true;
			return false;
		}

		public boolean isBeginStep() {return (getInStep().size()<=0);}
		public boolean isEndStep() {return (getOutStep().size()<=0);}

		public void setName(String s) {_name=s;}
		public void setId(String s) {_id=s;}
		public void setCreator(String s) {_creator=s;}
		public void setAssignTo(String s) {_assign=s;}
		public void setWorkBy(String s) {_workBy=s;}
		public void setInToken(int i) {_inToken=i;}

		public void addParent(String pId)
		{
			for (int i=0; i<_inStepArr.size(); i++)
			{
				if (_inStepArr.get(i).equals(pId))
					return;		// already is a parent
			}
			_inStepArr.add(pId);
		}

		public void setOutStep(String s)
		{
			// the input string can be a list of ID's separated by comma
			String [] sa = s.split(",");
			String idS;
			int len = sa.length;
			for (int i=0; i<len; i++)
			{
				idS = sa[i].trim();
				if (idS.length() <= 0) break;
				_outStepArr.add(sa[i].trim());
			}
		}

		// setChildrenLink at time of parsing XML
		public void setChildrenLink(HashMap <String,Step> stepMap)
		{
			// System.out.println("calling setChildrenLink() for " + getId()
			//		+ " with " + _outStepArr.size() + " child");			
			Step child;
			for (int i=0; i<_outStepArr.size(); i++) {
				child = stepMap.get(_outStepArr.get(i));
				_childArr.add(child);
				child.addParent(this.getId());			// add me as parent
				child.setChildrenLink(stepMap);
			}
		}

		// call to prepare for generating HTML
		// set the horizontal and vertical levels after parsing is done
		// first step is at level 0, up +ve, down -ve
		public void setLevel(int parentHLevel, int myVLevel, Flow parentFlow)
		{
			_levelH = parentHLevel+1;	// always one level from parent

			_levelV = myVLevel;

			int childNum = _childArr.size();
			int incV = childNum-1;		// 1 child is same level as me, 2 children add 1 level
			//boolean isOddNumOfChildren = (childNum != incV*2);

			if (parentFlow._right < _levelH)
				parentFlow._right = _levelH;// record max horizontal level

			for (int i=0; i<childNum; i++)
			{
				// do this only if _levelH is not set yet, otherwise earlier parent has already done this
				if (_childArr.get(i)._levelH <= 0)
					_childArr.get(i).setLevel(_levelH, _levelV+i, parentFlow);
			}

			if (parentFlow._bottom < _levelV+incV)
				parentFlow._bottom = _levelV+incV;	// record max bottom of the flow
		}

		/**
		 * fixOverlap() for Step
		 * call to prepare for generating HTML, must call setLevel() before calling this.
		 * fixOverlap() will put all needed info into table to start generating HTML
		 * @param row the row this step is in
		 * @param col the col this step is in
		 * @param table the latest table object we are working with
		 * @return
		 */
		public Object[][] fixOverlap(int row, int col, Object[][] table)
		{
			// my parent already ensure I have enough room
System.out.println("Call step.fixOverlap() for " + this.getName() + ": row="+row+", col="+col+", " +
		"table["+table.length+","+table[0].length+"]");
System.out.println("   content in cell " + (table[row][col]==null?"= null":"!= null"));
			while (table[row][col] != null)
			{
				// overlap, try the next row
				row++;
				if (table.length <= row)
					table = expandTable(table, 1, 0);
			}
			table[row][col] = this;				// * STEP: no overlap
System.out.println("++++ put " + getName() + " in [" + row + "," + col + "]");
			table[row+1][col] = this.getName();	// * name: cannot overlap on this row (I think)
System.out.println("++++ put name of " + getName() + " in [" + (row+1) + "," + col + "]");

			this._bInTable = true;

			boolean bMultiChildren = (_childArr.size()>1);

			// fix the case when I have multiple parents
			if (this.hasMultiParent())
			{
				table[row][col-1] = CON_VBOT;
System.out.println("   CON_VBOT mutliParent at [" + row + "," + (col-1) + "]");
			}

			// take care of children
			if (_childArr.size() > 0)
			{
				int tabRow = table.length;
				int tabCol = table[0].length;

				if (_childArr.size()>1)
				{
					if (tabCol-1 <= col)
					{
						table = expandTable(table, 0, 2);	// expand 2 columns for connect and children
						tabCol += 2;
					}
				}

				if (_childArr.size()>1 || childHasMultiParent())
					col++;

				int myRow = row;
				for (int i=0; i<_childArr.size(); i++)
				{
					Step child = _childArr.get(i);
					int incV = child._levelV - _levelV;	//(child._levelV>_levelV)?-1:((child._levelV<_levelV)?1:0);

					if (bMultiChildren)
					{
						// connector line after me
						if (i==0)
						{
System.out.println("   CON_VBOT at [" + row + "," + col + "]");
							table[myRow][col] = CON_VBOT;	// * top child: half v-connector line
						}
						else
						{
							row = myRow+2*incV;	// times 2 for step + name
System.out.println("   CON_V2 at [" + (row-1) + "," + (col) + "]");
							table[row-1][col] = CON_V2;	// * add long vertical line at step name row
System.out.println("   CON_VTOP at [" + (myRow+2*incV) + "," + col + "]");
							if (i == _childArr.size()-1) {
								table[row][col] = CON_VTOP;	// * bottom child: half v-connector line
							}
							else {
								table[row][col] = CON_V2;	// more children behind: long v-connector line
							}
						}
					}
					else if (child.hasMultiParent())
					{
						if (!child.isFirstParent(this))
						{
System.out.println("   CON_V2 at [" + (myRow-1) + "," + (col) + "]");
							table[myRow-1][col] = CON_V2;	// * add long vertical line at step name row
System.out.println("   CON_VTOP at [" + myRow + "," + col + "]");
							if (child.isLastParent(this)) {
								table[myRow][col] = CON_VTOP;	// * bottom child: half v-connector line
							}
							else {
								table[myRow][col] = CON_V2;		// more children behind: long v-connector line
							}
						}
					}

					// ECC TODO: need to fix the case where child's levelH is not 1 from me
					// 2 cases: levelH diff > 1 and < 1

					// put child in table
					if (!child._bInTable)
					{
						row = myRow + incV;
						table = child.fixOverlap(row, col+1, table);
					}
				}
			}
			return table;
		}

		private boolean childHasMultiParent()
		{
			for (int i=0; i<_childArr.size(); i++)
			{
				if (_childArr.get(i).getInStep().size() > 1)
					return true;
			}
			return false;
		}

		// expand table size in row and/or column
		private Object [][] expandTable (Object [][] table, int row, int col)
		{
System.out.println("****** expandTable by (" + row + "," + col + ")");
			int maxRow = table.length;
			int maxCol = table[0].length;

			Object [][] newTable = new Object[maxRow+row][maxCol+col];
			for (int i=0; i<maxRow; i++)
				for (int j=0; j<maxCol; j++)
					newTable[i][j] = table[i][j];

			// init new row
			for (int i=maxRow; i<maxRow+row; i++)
				for (int j=0; j<maxCol+col; j++)
					newTable[i][j] = null;

			// init new col
			for (int i=0; i<maxRow; i++)
				for (int j=maxCol; j<maxCol+col; j++)
					newTable[i][j] = null;

			return newTable;
		}	// END: expandTable()

		// move everything from this row and down by one
		private Object [][] moveDownOneRow(Object [][] table, int row)
		{
			int maxRow = table.length;
			int maxCol = table[0].length;

			if (row >= maxRow)
			{
				// need to expand by one row
				Object [][] newTable = new Object[maxRow+1][maxCol];
				for (int i=0; i<maxRow; i++)
					for (int j=0; j<maxCol; j++)
						newTable[i][j] = table[i][j];

				// no need to initialize because I am moving row down to cover new row
				maxRow++;
				table = newTable;
			}

			// move down 1 row
			for (int i=maxRow-2; i>=row; i--)
			{
				for (int j=0; j<maxCol; j++)
					table[i+1][j] = table[i][j];
			}
			return table;
		}	// END: moveDownOneRow()

		// get color by state
		// this will get the real-time state to get the color
		private final static int MIN_REALID = 1000;
		private String getColor()
		{
			int realId;
			if (_id!=null && (realId=Integer.parseInt(_id))>MIN_REALID) {
				// if the step correspond to a step instance object
				// get the real-time state
				try {
					PstFlowStep pstStep = (PstFlowStep) fsMgr.get(jwu, realId);
					this.setState(pstStep.getState());	// this will set _state accordingly
				}
				catch (PmpException e) {}
			}

			String colorStr;
			switch (_state)
			{
				case ST_NULL:
					colorStr = "#dddddd";
					break;
				case ST_NEW:
					colorStr = "#eeaa55";
					break;
				case ST_ACTIVE:
					colorStr = "#47C3F2";	// light blue
					break;
				case ST_COMMIT:
					colorStr = "#33ff33";
					break;
				case ST_ABORT:
					colorStr = "#ee0000";
					break;
				default:
					colorStr = "#dddddd";
					break;
			}
			return colorStr;
		}

		private String getPrefixBoxContent()
		{
			// when a step is selected, user may want to add a new step before or after it.
			// For begin step, you can only add after it.  For ending step, you can only add before it.
			// Other in-between step you can add both before or after.
			StringBuffer sBuf = new StringBuffer(256);
			String stepType;
			if (this.isBeginStep())
				stepType = TYPE_BEGIN;
			else if (this.isEndStep())
				stepType = TYPE_END;
			else
				stepType = TYPE_INBETWEEN;

			sBuf.append("<td width='15' align='center'>");
			if (_selectOption)
			{
				sBuf.append("<input type='radio' name='selectStep' value='" + getId()
						+ "' onClick='changeAtStep(\"" + stepType + "\", " + getId() + ");'>");
			}
			else
			{
				sBuf.append("<img src='../i/spacer.gif' width='15'/>");
			}
			sBuf.append("</td>");
			return sBuf.toString();
		}

		private void setSelect()
		{
			if (_state <= ST_NEW)
				_selectOption = true;
		}

		private static final String OUTSTEP	= "outstep";
		public String toString() {return toString(false);}
		public String toString(boolean bPack)
		{
			// bPack is false if we want to print out the step nicely and recursively
			// bPack is true if we need to pack only this step info into a String
			String newline="", indent="";
			if (!bPack)
			{
				newline = NEWLINE;
				indent  = INDENT;
			}
			StringBuffer sBuf = new StringBuffer(512);

			if (!bPack)
				sBuf.append(begStepTag + newline);
			sBuf.append(indent + ID + EQ + getId() + SEMICOLON + newline);
			sBuf.append(indent + NAME + EQ + getName() + SEMICOLON + newline);
			sBuf.append(indent + STATE + EQ + getStateString() + SEMICOLON + newline);
			sBuf.append(indent + CREATED + EQ + getCreatedDateString() + SEMICOLON + newline);
			sBuf.append(indent + EXPIRE + EQ + getExpireDateString() + SEMICOLON + newline);
			sBuf.append(indent + CREATOR + EQ + getCreator() + SEMICOLON + newline);
			sBuf.append(indent + ASSIGN + EQ + getAssignTo() + SEMICOLON + newline);
			sBuf.append(indent + WORKBY + EQ + getWorkBy() + SEMICOLON + newline);
			sBuf.append(indent + INTOKEN + EQ + getInToken() + SEMICOLON + newline);

			sBuf.append(indent + OUTSTEP + EQ);
			String aStepId;
			for (int i=0; i<_outStepArr.size(); i++)
			{
				if (i > 0) sBuf.append(", ");
				aStepId = _outStepArr.get(i);
				if (bPack)
					sBuf.append(getFlow().getStepMap().get(aStepId).getName());	// use name
				else
					sBuf.append(aStepId);		// use id
			}
			sBuf.append(SEMICOLON + newline);

			sBuf.append(indent + INSTEP + EQ);
			for (int i=0; i<_inStepArr.size(); i++)
			{
				if (i > 0) sBuf.append(", ");
				aStepId = _inStepArr.get(i);
				if (bPack)
					sBuf.append(getFlow().getStepMap().get(aStepId).getName());	// use name
				else
					sBuf.append(aStepId);		// use id
			}
			sBuf.append(SEMICOLON + newline);

			if (!bPack)
			{
				sBuf.append(indent + LEVELH + EQ + _levelH + SEMICOLON + newline);
				sBuf.append(indent + LEVELV + EQ + _levelV + SEMICOLON + newline);
				sBuf.append(endTag + newline);
			}

			// recursive
			if (!bPack)
			{
				for (int i=0; i<_childArr.size(); i++)
				{
					Step aStep = _childArr.get(i);
					if (aStep!=null && aStep.isFirstParent(this))
						sBuf.append(aStep.toString());
				}
			}

			return sBuf.toString();
		}

		private void setNewChild(Step child)
		{
			this._outStepArr = new ArrayList<String>();
			this.setOutStep(child.getId());
			this._childArr = new ArrayList<Step>();
			this._childArr.add(child);
		}

		private void replaceParent(String oldParentId, ArrayList<String> newParentArr)
		{
			for (int i=0; i<_inStepArr.size(); i++)
			{
				if (_inStepArr.get(i).equals(oldParentId))
				{
					_inStepArr.remove(i);
					break;
				}
			}
			if (newParentArr != null)
				_inStepArr.addAll(newParentArr);
		}

		private void replaceChildren(String oldChildId,
				ArrayList<String>newChildArr, HashMap<String,Step>stepMap)
		{
			for (int i=0; i<_outStepArr.size(); i++)
			{
				if (_outStepArr.get(i).equals(oldChildId))
				{
					_outStepArr.remove(i);		// remove old child
					break;
				}
			}
			if (newChildArr != null)
				_outStepArr.addAll(newChildArr);

			// also need to fix _childArr (array of Step)
			for (int i=0; i<_childArr.size(); i++)
			{
				if (_childArr.get(i).getId().equals(oldChildId))
				{
					_childArr.remove(i);		// remove old child
				}
			}
			if (newChildArr != null)
			{
				for (int i=0; i<newChildArr.size(); i++)
				{
					Step aChild = stepMap.get(newChildArr.get(i));
					if (aChild != null)
						_childArr.add(aChild);
				}
			}
		}	// END: replaceChildren()
		
		/**
		 * translate taskState into step state
		 */
		public static String stateMapping(String taskState)
		{
			if (taskState == null) return null;
			
			String stepSt = null;			

			if (taskState.equals(task.ST_NEW))
				stepSt = PstFlowConstant.ST_STEP_NEW;
			else if (taskState.equals(task.ST_OPEN) ||
					 taskState.equals(task.ST_ONHOLD) ||
					 taskState.equals(task.ST_LATE))
				stepSt = PstFlowConstant.ST_STEP_ACTIVE;
			else if (taskState.equals(task.ST_COMPLETE))
				stepSt = PstFlowConstant.ST_STEP_COMMIT;
			else if (taskState.equals(task.ST_CANCEL))
				stepSt = PstFlowConstant.ST_STEP_ABORT;

			return stepSt;
		}

	}	// END: Step class

}