<%
//
//	Copyright (c) 2008, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//	File:	post_q_respond.java
//	Author: ECC
//	Date:		01/08/2008
//	Description:	Post file for handling the answer.  It creates an answer object
//				if that doesn't exist yet (or open it) and saves the result.  It also
//				aggregate the result into the Summary attribute of the parent question.
//
//	Modification:
//				@ECC011908	For circle members who are not an attendee, they can still participate
//							the quest.  Attendee is just for notification.
//
/////////////////////////////////////////////////////////////////////
//
%>

<%@ page import = "oct.codegen.*" %>
<%@ page import = "oct.pst.*" %>
<%@ page import = "oct.pep.PepCommentVector" %>
<%@ page import = "oct.pmp.exception.*" %>
<%@ page import = "util.*" %>
<%@ page import = "java.util.*" %>
<%@ page import = "java.io.*" %>
<%@ page import = "java.text.*" %>

<%@ taglib uri="/pmp-taglib" prefix="pmp" %>
<pmp:useUser id="pstuser" noSessionUrl="../out.jsp" />

<%
	request.setCharacterEncoding("utf8");
	response.setCharacterEncoding("utf8");

	// create quest object
	PstUserAbstractObject me = pstuser;

	if (me instanceof PstGuest)
	{
		response.sendRedirect("../out.jsp?msg=Access declined");
		return;
	}
	
	int myUid = me.getObjectId();
	String myUidS = String.valueOf(myUid);
	String myName = ((user)me).getFullName();

	questManager qMgr		= questManager.getInstance();
	answerManager aMgr		= answerManager.getInstance();
	answer aObj = null;

	String s;
	boolean bSaveOnly = false;			// true: save only; false: submit
	
	String qidS = request.getParameter("qid");
	s = request.getParameter("save");
	if (s!=null && s.equals("true"))
		bSaveOnly = true;				// just saving temporary work, don't do summary
		
	Date now = new Date();
		
	// this might be an update of the answer saved
	String aidS = request.getParameter("aid");
	if (aidS!=null && aidS.length()>0)
		aObj = (answer)aMgr.get(me, aidS);
	else
	{
		// create the answer object
		aObj = (answer)aMgr.create(me);
		aidS = String.valueOf(aObj.getObjectId());
		aObj.setAttribute("Creator", myUidS);
		aObj.setAttribute("CreatedDate", now);
		aObj.setAttribute("TaskID", qidS);
	}

	
	// save the answer
	aObj.setAttribute("LastUpdatedDate", now);
	if (bSaveOnly)
		aObj.setAttribute("State", quest.ST_ACTIVE);	// saved for later
	else
		aObj.setAttribute("State", quest.ST_CLOSE);		// done

	// go through the responses
	String temp;
	int num, choiceNum;
	int totalQuestion = Integer.parseInt(request.getParameter("totalQuestion"));
	
	// each element is a complete answer string of a question
	// KEY:  @@ separates questions; $@$ separates checkboxes; :: separates choice and input
	// 3::this is good@@2::checkbox3 is good$@$4::checkbox5 also good@@ ...
	String [] multiS = new String[quest.MAX_QUESTIONS];
	for (int i=0; i<multiS.length; i++) multiS[i] = "";	// initialize
	
	// ans is used to remember the chices of radio and checkbox
	// for checkbox it could be multiple answer like 3,4,6 (checked 3 boxes)
	String [] ans = new String[quest.MAX_QUESTIONS];
	for (int i=0; i<ans.length; i++) ans[i] = "";		// initialize
	
	String [] sa;
	
	// first loop: get the answers of the multiple choice questions
	for (Enumeration e = request.getParameterNames() ; e.hasMoreElements() ;)
	{
		temp = (String)e.nextElement();
		if (temp.startsWith("R_") || temp.startsWith(("C_")) )
		{
			// radio: multiple choice response
			s = temp.substring(2);
			if (s.indexOf('.') != -1)
				s = s.substring(0, s.indexOf('.'));
			num = Integer.parseInt(s) - 1;			// R_1, R_2, etc. or C_1, C_2, etc.
			s = request.getParameter(temp);		// question #N uses index (N-1)
			if (ans[num].length() > 0)
				ans[num] += ",";		// checkbox may have more than one answer
			ans[num] += s;				// remember the answer for summary.  Note answer A is 1
			//multiS[num] = ans[num];		// just use it for comparison later
//System.out.println(temp);
			//System.out.println("answer for " + temp + " = " + multiS[num]);			
		}
	}
	
	// sort each answer if necessary
	for (int i=0; i<ans.length; i++) {
		if (ans[i] == "") continue;
		sa = ans[i].split(",");
		if (sa.length > 1) {
			Arrays.sort(sa);
			ans[i] = sa[0];
			for (int j=1; j<sa.length; j++)
				ans[i] += "," + sa[j];
		}
		System.out.println("ans["+i+"]="+ans[i]);
	}

	double [][] numericInput = new double[totalQuestion][quest.MAX_CHOICES];	// store numeric input for summary later
	String [] lastComment = new String[totalQuestion+1];
	for (int i=0; i<=totalQuestion; i++) lastComment[i] = null;			// init
	
	// 2nd loop: get the numeric, string or paragraph inputs from each questions and append the result
	String constructOneAnswer;
	for (Enumeration e = request.getParameterNames() ; e.hasMoreElements() ;)
	{
		temp = (String)e.nextElement();
		if ( (temp.startsWith("N_")) || (temp.startsWith("S_")) || (temp.startsWith("P_")) )
		{
			// input of type numeric, string or paragraph
			// numeric input: N_2.1, N_1.3, etc.
			// string input: S_2.1, S_21.3, etc.
			// paragraph input: P_2.1, P_21.3, etc.  OR P_2.3.0 (last non-MC input)
			s = temp.substring(2, temp.indexOf("."));	// extract the first digit, e.g. 12 from N_12.1
			num = Integer.parseInt(s) - 1;				// num is the question# starts from 0
			constructOneAnswer = "";
			
			// extract 2nd digit but there might be a third digit "0"
			sa = temp.split("\\.");
			s = sa[1];									// extract the 2nd digit, e.g. 4 from N_12.4
			choiceNum = Integer.parseInt(s) - 1;		// choiceNum is the choice of a question starts from 0
			if (ans[num] == "")
			{
				multiS[num] = "1" + quest.DELIMITER;	// no multiple choice: probably paragraph input
				ans[num] = "1";							// treat it as choosing the first answer.
				//totalQuestion++;						// need to cover this question even though it's not multi-choice
			}
			else
			{
				// make sure the MC answer match before extracting the input
				if (JwTask.foundAnswer(ans[num], s)) {
					constructOneAnswer = s + quest.DELIMITER;	// this will be "3::"
					//multiS[num] += quest.DELIMITER;		// add "::"
				}
				else
				{
					// still possible that this is a last paragraph input on the question
					if (sa.length>=3 && sa[2].equals("0"))	// P_2.4.0
					{
						// save the lastComment because the loop may not be in order
						lastComment[num] = quest.DELIMITER + request.getParameter(temp);
					}
					continue;							// this answer is not chosen, keep going
				}
			}
			s = request.getParameter(temp);				// the input value (number or text)
			if (temp.startsWith("N_"))
			{
				if (s.trim().length() == 0) s = "0";	// not entering is 0
				numericInput[num][choiceNum] = Double.parseDouble(s);// remember the numeric input for aggregation later
			}
			constructOneAnswer += s;		// 3::55 or 3::this is a good choice
			//multiS[num] += s;			// 3::55 (3 is the multiple choice ans and 55 is the numeric input)
			if (multiS[num] != "")
				multiS[num] += "$@$";	// separate from the last checkbox choice of this question
			multiS[num] += constructOneAnswer;
		}
	}
	
	// multiS contains answer to each questions.  If there was no extra input to a question,
	// then I will simply use the radio or checkbox choice as the answer
	for (int i=0; i<totalQuestion; i++) {
		if (multiS[i] == "") {
			multiS[i] = ans[i].replaceAll(",", "\\$@\\$");
		}
	}
	
	// put the last comment into the multiS array
	for (int i=0; i<totalQuestion; i++)
	{
		if (lastComment[i] != null)
		{
			if (multiS[i] == null)
				multiS[i] = lastComment[i];
			else
				multiS[i] += lastComment[i];
		}
	}
	
	// put the array result into Content
	StringBuffer sBuf = new StringBuffer();
//System.out.println("total q="+totalQuestion);	
	for (int i=0; i<totalQuestion; i++)
	{
		if (multiS[i] == null) break;
		if (i > 0) sBuf.append(quest.DELIMITER1);		// "@@" separate questions
		sBuf.append(multiS[i]);
//System.out.println("multi " + i +"=" + multiS[i]);		
	}
	
	aObj.setAttribute("Content", sBuf.toString().getBytes("UTF-8"));
	
	// commit changes to answer
	aMgr.commit(aObj);
	
	quest qObj = (quest)qMgr.get(me, qidS);
	
	// ECC: is this really being used?  q_answer.jsp is aggregating the summary by
	// iterating through the answer objects of all the responders.
	// ECC: Yes: it is being used when user display Summary info.  In that case it will need
	// to look at the Summary field of quest object.
	// e.g. of summary (2 questions) 1::1::0#0::0::0@@2::2::0::0::0::0
	// 2 questions: first has 3 choices, second has 4 choices. First quest, 1st choice has an numeric input
	
	// perform summary on question object
	// need to synchronize
	if (!bSaveOnly)
	{
		// Submitted the result to the pool
		sBuf = new StringBuffer();
		int idx, idx1;
		double sumInput=0.0;
		boolean bNumericInput;
		
		// ECC: as far as I can remember, we are not using summary for now, just in case in
		// the future if we have thousands of responses, this might become necessary.
		// even approximation can help.  No need to be precise.
		// Oops, with the exception that I use this to sum up a numeric input
		synchronized (quest.class)
		{
			String sumS = (String)qObj.getAttribute("Summary")[0];		// should not be null unless corruption
			System.out.println("-----\nOriginal summary: " + sumS);
	
			if (sumS != null)
			{
				// now start to aggregate the answer
				// question#::#OfUser not answer::5::0::1@@ ...
				// each digit represents # of users choosing that answer
				// In this example, it would be 5 users choosing A, 0-B, and 1-C
				sa = sumS.split(quest.DELIMITER1);		// sa.length should == totalQuestion
				if (sa.length != totalQuestion)			// this is possible if I added new questions to the quest
					System.out.println("!!! post_q_respond.jsp: #of question in summary (" + sa.length + ") != totalQuestion (" + totalQuestion + ")");
	
				String [] sa1;
				String [] saAnswer;
				int iAns;
				for (int i=0; i<sa.length; i++)
				{
					// for each question: question #i (i starts from 0)
					// sa1 is the old answer string of this question in the summary
					sa1 = sa[i].split(quest.DELIMITER);				// ready to extract the answer w/i a question
					idx = 0;
					sBuf.append(sa1[idx++] + quest.DELIMITER);		// question #
					num = Integer.parseInt(sa1[idx++]);				// no. of user not answer this question yet
					if (multiS[i] != null)
						num--;										// I answered: decrement by 1
					sBuf.append(num);								// put no. of user not answer back
	
					// now process each answer the user gave
					saAnswer = ans[i].split(",");	// 3,5,6 (checkboxes chosen)
					for (int j=0; j<saAnswer.length; j++) {
						if (StringUtil.isNullOrEmptyString(saAnswer[j]))
							continue;			// for bullet, there is no answer
							
						iAns = Integer.parseInt(saAnswer[j]);
						// answer A is 1, not 0.  But need to offset on summary by 2, therefore add 1
						num = iAns + 1;
						if (num >= sa1.length) continue;	// ECC: for safety
						//System.out.println("my answer is " + ans[i]);
						
						// copy answers before this choice
						for (int k=idx; k<num; k++) {
							sBuf.append(quest.DELIMITER + sa1[k]);
							idx++;
						}
						
						bNumericInput = false;
//System.out.println("num=" + num);
//System.out.println("sa1 length=" + sa1.length);
						s = sa1[num];			// current no. of ppl choosing this answer
						if ((idx1 = s.indexOf(quest.DELIMITER2)) != -1)
						{
							// there is a numeric input for this answer
							sumInput = Double.parseDouble(s.substring(idx1+1)) + numericInput[i][iAns-1];
							s = s.substring(0, idx1);					// s was the original # of user picking this answer
							bNumericInput = true;
						}
						sBuf.append(quest.DELIMITER + (Integer.parseInt(s) + 1));	// put the new # of user value back to summary
						if (bNumericInput)
						{
							// copy the sum value of numeric input back
							sBuf.append(quest.DELIMITER2 + sumInput);
						}
					}
					
					// copy the rest of the answers back to summary
					for (int j=num+1; j<sa1.length; j++)
						sBuf.append(quest.DELIMITER + sa1[j]);
					//System.out.println("new sumary for question #" + (i+1) + ": " + sBuf.toString());
					
					// save the summary of this question
					if (i < sa.length-1)
						sBuf.append(quest.DELIMITER1);				// separate answer to questions by "@@"
				}
				qObj.setAttribute("Summary", sBuf.toString());
				qObj.appendAttribute("Attendee", myUidS);
				qMgr.commit(qObj);
				//System.out.println("+++ Final new summary: " + sBuf.toString());			
			}
		}	// END synchronized code
		
		// @ECC101807 event triggers: only if it is committed (submitted)
		if (qObj.getAttribute("Type")[0].equals(quest.TYPE_EVENT))
			s = PrmEvent.EVT_INV_REPLY;
		else
			s = PrmEvent.EVT_QST_REPLY;
		String circleIdS = (String)qObj.getAttribute("TownID")[0];
		
		// I might be submitted again and again, so remove the old event before creating new
		String expr = "MeetingID='" + aidS + "' && Creator='" + myUid + "' && Type='" + s + "'";
		PrmEvent.checkCleanMaxEvent(me, expr, 0);
		PrmEvent.createTriggerEvent(me, s, aidS, circleIdS, null);
	}	//	if it is done, doing summary
	
	if (bSaveOnly)
		response.sendRedirect("q_respond.jsp?qid="+qidS);			// allow user to keep updating
	else
		response.sendRedirect("q_answer.jsp?aid="+aidS);			// display result q_answer.jsp

%>
