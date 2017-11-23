//
//  Copyright (c) 2004, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   JwTask.java
//  Author:	ECC
//  Date:   04.18.2004
//  Description:	Process and create a list of tasks to represent a project plan.
//
//  Modification:
//		@ECC021207	Support moving of node and its subtree (Singapore)
//		@ECC010208	Support questionnaire and invite
//
/////////////////////////////////////////////////////////////////////
//

package util;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Hashtable;
import java.util.Vector;

import org.apache.log4j.Logger;

import oct.codegen.answerManager;
import oct.codegen.planTask;
import oct.codegen.planTaskManager;
import oct.codegen.quest;
import oct.codegen.task;
import oct.codegen.user;
import oct.codegen.userManager;
import oct.pmp.exception.PmpException;
import oct.pst.PstUserAbstractObject;

public class JwTask
{
	private String m_name = null;
	private int m_level;
	private int m_order;
	private int m_preOrder;
	private String m_parentId;
	private int m_startGap;		// the distance between task start date and project start date in days
	private int m_length;			// task duration in days

	private int m_offset;
	public final static int MAX_TASKS = 1500;
	public final static int MAX_LEVEL = 10;
	public final static int MAX_NUM = 4;

	public final static String INPUT_NUMBER	= "_#";
	public final static String INPUT_STRING	= "_?";
	public final static String INPUT_PARAGH	= "_??";
	public final static String INPUT_STRING_RGX	= "_\\?";
	public final static String INPUT_PARAGH_RGX	= "_\\?\\?";

	public final static String NUM_NAME = "@NUM_NAME@";		// HTML field to get user input
	public final static String STR_NAME = "@STR_NAME@";
	public final static String PGH_NAME = "@PGH_NAME@";

	public final static String END_BLKT = "'>";

	private static userManager uMgr;
	private static planTaskManager ptMgr;

	private static Logger l;
	static {
		l = PrmLog.getLog();
		try {
			uMgr = userManager.getInstance();
			ptMgr = planTaskManager.getInstance();
		}
		catch (PmpException e) {}
	}

	public JwTask() {}

	public JwTask(String name, int level, int order, int preOrder, int length, int startGap)
	{
		m_name = name;
		m_level = level;
		m_order = order;
		m_preOrder = preOrder;
		m_length = length;
		m_startGap = startGap;
	}


	public String getName() {return m_name;}
	public Integer getLevel() {return new Integer(m_level);}
	public Integer getOrder() {return new Integer(m_order);}
	public Integer getPreOrder() {return new Integer(m_preOrder);}
	public String getParentId() {return m_parentId;}
	public void setParentId(String idS) {m_parentId = idS;}
	public Integer getLength() {return new Integer(m_length);}
	public Integer getStartGap() {return new Integer(m_startGap);}

	private void startProcess() {m_offset = 0;}

	private String readLine(String s)
	{
		int len = s.length();
		if (m_offset >= len)
			return null;						// EOF

		StringBuffer line = new StringBuffer();
		while (m_offset < len)
		{
			if ((s.charAt(m_offset) == -1) || (s.charAt(m_offset) == '\n'))
				break;
			line.append(s.charAt(m_offset++));
		}
		m_offset++;
		return line.toString();
	}

	public JwTask [] processScript(String planScript)
		throws PmpException
	{
		JwTask [] jwArray = new JwTask[MAX_TASKS];	// support a max of 300 tasks for now
		int preOrder = 0;
		int lastLevel = 0;
		int lastOrder = 0;
		int order = 0;
		int firstNum = 0;
		int i, level;
		int count = 0;			// total no. of task in plan
		String line;
		int idx, idx1, length, startGap;

		String[] parentIDArray = new String[MAX_LEVEL];	// max 10 levels
		int pTaskId = 1;							// fake no. to be replaced on actual creation
		String lastObjectID = "0";
		boolean bHasLevel0 = false;					// trap the case that there is no top level at all
		parentIDArray[lastLevel] = lastObjectID;
		String s;

		startProcess();
		
		// #=comment; *=MC bullet; *@=checkbox bullet; *&=just bullet

		//while (line != null)
		do
		{
			line = readLine(planScript);
			if (line == null) break;	// EOF

			line = line.trim();
			if ((line.length() == 0) || (line.charAt(0) == '#')) continue;

			// use "***" to denote sublevels.  Top level (0) has no "*"
			String name = null;
			if (line.charAt(0) != '*')
			{
				// top level
				i = 1;					// i-1 is the num of *
				level = 0;
				order = firstNum++;		// my last digit
				lastOrder = 0;
				bHasLevel0 = true;
			}
			else
			{
				i=0;
				while (line.charAt(i++) == '*');		// skip to count *
				
				level = i-1;							// i-1 is the num of *
				if (!bHasLevel0)
				{
					throw new PmpException("Level specification error found on task (you must start with top level 0 without an asterisk): "
							+ line.substring(i-1).trim());
				}
				if (level-lastLevel > 1)
				{
					throw new PmpException("Level specification error found on task: " +line.substring(i-1).trim());
				}
				if (i > line.length())
					continue;			// the line contains only *, ignore
				if (level == lastLevel)
					order = ++lastOrder;
				else if (level > lastLevel)	// can only be one greater
				{
					order = 0;
					lastOrder = 0;
				}
				else 						// level < lastLevel
				{
					int j;
					for (j=count-1; j>=0; j--)
						if (jwArray[j].getLevel().intValue() == level) break;
					order = jwArray[j].getOrder().intValue() + 1;
					lastOrder = order;
				}
			}
			name = line.substring(i-1).trim();	// the name of the task

			/////////////////////
			// @ECC010208 special coding for obtaining inputs from user
			// _# enter numeric; _? enter string; _?? textArea
			name = name.replaceAll(INPUT_NUMBER, "&nbsp;<input class='formtext' type='text' size='2' name='" + NUM_NAME + "'>&nbsp;");
			if ((idx = name.indexOf(INPUT_PARAGH)) != -1)
			{
				s = "<textarea class='formtext' type='text' rows='5' cols='80' name='" + PGH_NAME + "'></textarea>";
				if (idx > 1)	// idx=0 can be the "-" sign
					s = "<br>" + s;		// there are other instructional text before the paragraph, add line break
				name = name.replaceAll(INPUT_PARAGH_RGX, s);
			}
			name = name.replaceAll(INPUT_STRING_RGX, "&nbsp;<input class='formtext' type='text' size='25' name='" + STR_NAME + "'>&nbsp;");
			// @ECC010208 End

			// get task duration and start gap
			startGap = 0;
			length = 0;
			idx = name.indexOf("::");			// look for duration of task "taskName::startGap,length"
			if (idx > 0)
			{
				idx1 = name.lastIndexOf(',');
				startGap = Integer.parseInt(name.substring(idx+2, idx1).trim());
				length = Integer.parseInt(name.substring(idx1+1).trim());
				name = name.substring(0, idx).trim();
			}

			// Everything is ready: level, order, preOrder, name
			JwTask aJwTask = new JwTask(name, level, order, preOrder, length, startGap);
			preOrder++;			// constantly monotonically increasing
			if (lastLevel < level)
			{
				for (int k = lastLevel + 1 ; k < level + 1; k++)
				{
					parentIDArray[k] = lastObjectID;
				}
			}
			aJwTask.setParentId(parentIDArray[level]);

			lastLevel = level;
			lastObjectID = String.valueOf(pTaskId++);
			jwArray[count++] = aJwTask;
			if (count > MAX_TASKS)
			{
				System.out.println("ERROR: this license of PRM only supports a maximum of " + MAX_TASKS + " tasks in a project.");
				break;				// reach the limit
			}

		} while (true);

		if (count == 0) return null;
		return jwArray;
	}

	public static void insertTask(Vector nPlan, Vector oPlan, Hashtable oTask, int level, int order, int idx)
	{
		Integer [] io;
		Hashtable <String, Object> newTask = new Hashtable<String, Object>();
		newTask.put("PlanID", oTask.get("PlanID"));
		io = new Integer[1];
		io[0] = new Integer(order);
		newTask.put("Order", io);
		io = new Integer[1];
		io[0] = new Integer(level);
		newTask.put("Level", io);
		newTask.put("TaskID", oTask.get("TaskID"));
		newTask.put("ProjectID", oTask.get("ProjectID"));
		newTask.put("Name", oTask.get("Name"));
		if (((String)oTask.get("Status")).equals(task.NEW))
			newTask.put("Status", task.NEW);		// keep the NEW status after a move
		else
			newTask.put("Status", task.CHANGE);
		nPlan.addElement(newTask);

		// all the task of this level that are located after this task needs to
		// increment order by 1
		Hashtable aTask;
		for (int i=idx; i<oPlan.size(); i++)
		{
			aTask = (Hashtable)oPlan.elementAt(i);
			int l = ((Integer)((Object [])aTask.get("Level"))[0]).intValue();
			if (l < level)
				break;
			else if (l == level)
			{
				io = new Integer[1];
				int o = ((Integer)((Object [])aTask.get("Order"))[0]).intValue()+1;
				io[0] = new Integer(o);
				aTask.put("Order", io);
			}
		}
	}

	public static void printPlan(Vector plan)
	{
		for (int i=0; i<plan.size(); i++)
		{
			Hashtable aTask = (Hashtable)plan.elementAt(i);
			//System.out.println("***" + aTask.get("Name"));
			int l = ((Integer)((Object [])aTask.get("Level"))[0]).intValue();
			int o = ((Integer)((Object [])aTask.get("Order"))[0]).intValue();
			//System.out.print("[" + l + "," + o + "] ");
			//System.out.println(aTask.get("Name") + " (" + aTask.get("Status").toString().charAt(0) + ")");
		}
	}

	public static int compare(String level1, String level2)
	{
		// replace getHeaderIntValue() which has a bug
		// comparing two levelInfo.  E.g. 2.1.2 and 2.1.11
		// return  0 if level1 == level2  or any null or any illegal char
		// return -1 if level1 <  level2
		// return +1 if level1 >  level2
		if (level1==null || level2==null) return 0;
		String [] sa1 = level1.split("\\.");		// JDK 5.0.9 and up uses regex rathen than string
		String [] sa2 = level2.split("\\.");
		int len = sa1.length;
		if (sa2.length < len) len = sa2.length;		// compare up to the shorter one

		int i1, i2;
		for (int i=0; i<len; i++)
		{
			try {i1 = Integer.parseInt(sa1[i].trim());}
			catch (Exception e) {return 0;}
			try {i2 = Integer.parseInt(sa2[i].trim());}
			catch (Exception e) {return 0;}
			if (i1 > i2) return 1;
			if (i2 > i1) return -1;
		}

		// after comparing the minimum length, if they are equal, then the longer level string is larger
		if (sa1.length > sa2.length) return 1;
		if (sa1.length < sa2.length) return -1;
		return 0;		// the two level string are exactly the same
	}

	public static void fixHeader(Vector plan)
	{
		fixHeader(plan, null, false);
	}
	
	public static void fixHeader(Vector plan, PstUserAbstractObject u, boolean bSavetoDB)
	{
		Hashtable aTask;
		int level, lastLevel=-1, order=0;
		Integer [] io;
		int [] orderOfLevel = new int[MAX_LEVEL];
		int oldOrder;
		task tObj;

		for (int i=0; i<MAX_LEVEL; i++)
			orderOfLevel[i] = 0;	// init

		for (int i=0; i<plan.size(); i++)
		{
			// assume level is right, ignore current order and fix it through the pass
			aTask = (Hashtable)plan.elementAt(i);
			if (aTask.get("Status").equals(task.DEPRECATED))
				continue;
			
			oldOrder = ((Integer)((Object [])aTask.get("Order"))[0]).intValue();

			level = ((Integer)((Object [])aTask.get("Level"))[0]).intValue();
			if (level > lastLevel)
				order = 0;		// indent further, start from 0
			else if (level == lastLevel)
				order++;
			else
				order = orderOfLevel[level] + 1;
			orderOfLevel[level] = order;
			lastLevel = level;

			// set the correct level
			if (oldOrder != order) {
				if (aTask.get("TaskID") != null)
					l.info("Out of order detected on task [" + aTask.get("TaskID").toString() + "]");
				io = new Integer[1];
				io[0] = new Integer(order);
				aTask.put("Order", io);
				
				// save the correction to DB
				if (bSavetoDB) {
					try {
						tObj = (task)aTask.get("Task");
						planTask pt = tObj.getPlanTask(u);
						pt.setAttribute("Order", order);
						ptMgr.commit(pt);
						l.info("   Fixed planTask [" + pt.getObjectId() + "]");
					}
					catch (PmpException e) {}
				}
			}
		}
	}

	// This is for creating a Vector from a text Questionnaire.
	public static Vector getAgendaVector(String agendaS)
		throws PmpException
	{
		// Questionnaire is represented by a Vector of JwTask
		// Task is represented by a hash table.
		Vector rAgenda = new Vector();
		String s, msg;
		int i = 0;

		// process the plan script to create a list of JwTask
		JwTask [] taskArray = null;
		try
		{
			JwTask jw = new JwTask();
			taskArray = jw.processScript(agendaS);
		}
		catch (PmpException e)
		{
			String [] st = e.toString().split(":");
			msg = st[1];
			msg += ": \"<b>" + st[2] + "</b>\"";
			throw new PmpException(msg);
		}

		while (true)
		{
			// pTask is the persistent Task
			// rTask is the ram task which is in cache
			if (taskArray==null || taskArray[i] == null) break;

			JwTask pTask = taskArray[i++];
			s = pTask.getName();
			if (s.length() >= 400)
			{
				msg = "The following question is longer than the maximum characters (400) allowed:<blockquote>" + s + "</blockquote>";
				throw new PmpException(msg);
			}
			Hashtable rTask = new Hashtable();
			rTask.put("Order", pTask.getOrder());
			rTask.put("Level", pTask.getLevel());
			rTask.put("Name", s);

			rAgenda.addElement(rTask);
		}
		return rAgenda;
	}	// END: getAgendaVector()

	// go through the vector to see how many questions are there
	public static int getTotalQuestion(Vector rAgenda)
	{
		int total = 0, level;
		Integer pLevel;

		for (int i=0; i<rAgenda.size(); i++)
		{
			Hashtable rTask = (Hashtable)rAgenda.elementAt(i);
			pLevel = (Integer)rTask.get("Level");
			level = pLevel.intValue();
			if (level == 0) total++;
		}
		return total;
	}


	// output HTML string for the questionnaire
	// this is call is either print a quest to request for input
	// or print answer for a particular user and request for update
	public static String printQuest(
			Vector rAgenda,
			StringBuffer summaryB,					// pass summaryB on initialization
			int numOfUser,							// total attendees getting this quest
			String [] ans,							// the answer array of a particular user
			String [][] inputArr)					// the input array of a particular user
	{
		// when the quest is first constructed, I will pass in a summary StringBuffer and
		// get the initial summary string back.
		StringBuffer sBuf = new StringBuffer(1024);
		String[] levelInfo = new String[10];
		boolean isParagraph = false;
		boolean isLastAns = false;
		boolean isBullet;
		int questNum=0, choiceNum=0;
		String ansStr;
		Hashtable<String, Object> rTask;
		String s;

		int i = 0;
		
		// check to see if there is a Beginning Statement
		while (rAgenda.size() > i) {
			rTask = (Hashtable)rAgenda.elementAt(i);
			s = ((String)rTask.get("Name")).trim();
			if (s.startsWith("-")) {
				s = s.substring(1).trim();				// skip the "-"
				sBuf.append("<tr><td colspan='2'><img src='../i/spacer.gif' height='15' /></td></tr>");
				sBuf.append("<tr><td colspan='2'  class='plaintext_big' valign='top' width='10'>");
				sBuf.append(s);
				sBuf.append("</td></tr>");
				
				i++;			// skip one task
				continue;
			}
			break;
		}
		
		
		for(; i < rAgenda.size(); i++)
		{
			rTask = (Hashtable)rAgenda.elementAt(i);
			String pName = (String)rTask.get("Name");

			Integer pLevel = (Integer)rTask.get("Level");
			Integer pOrder = (Integer)rTask.get("Order");

			int level = pLevel.intValue();
			int order = pOrder.intValue();

			int width = 10 + 22 * level;
			order++;
			isBullet = false;
			
			if (level == 0)
			{
				levelInfo[level] = String.valueOf(order);
				isLastAns = false;
				isParagraph = false;
				questNum = order - 1;			// question# starts from 0
				if (summaryB != null)
				{
					// question#::#OfUser not answer::5::0::1@@ ... each digit represents # of users choosing that answer
					if (summaryB.length() > 0)
						summaryB.append(quest.DELIMITER1);				// separate the questions
					summaryB.append(levelInfo[level] + quest.DELIMITER + numOfUser);	// question # (e.g. 1::15, 2::15, etc.)
				}
			}
			else
			{
				if (isLastAns) continue;		// ignore the other multiple choice behind this
				levelInfo[level] = levelInfo[level - 1] + "." + order;
				choiceNum = order - 1;			// choice# starts from 0
				if (summaryB != null)
					summaryB.append(quest.DELIMITER + "0");	// # of user choosing this answer
			}

			// -- list the table of agenda items
			if (level <= 0)
				sBuf.append("<tr><td colspan='2'><img src='../i/spacer.gif' height='15' /></td></tr>");

			sBuf.append("<tr><td class='plaintext_big' valign='top' width='10'>");
			if (isParagraph) sBuf.append("<br>");	// last was a paragraph, insert a space line
			sBuf.append("<img src='../i/spacer.gif' width='" + width + "' height='0' border='0'>");

			if (level <= 0)
			{
				// top level: this is the question
				sBuf.append(levelInfo[level]);
				sBuf.append("</td>");
				sBuf.append("<td class='plaintext_big' valign='top'>");
			}
			else if (pName.indexOf(PGH_NAME)==-1 || pName.charAt(0)!='-')
			{
				// radio or checkbox or bullet
				// the multiple choice or option questions (radio): R_1, R_2, etc.
				// checkbox: C_1.1, C_1.2, etc
				// answer starts from 1, 2, 3, ...
				sBuf.append("</td><td class='plaintext_big' valign='top'>");

				// checkbox (lines denoted by "*@")
				if (pName.charAt(0) == '@') {
					pName = pName.substring(1);
					sBuf.append("<input type='checkbox' name='C_" + levelInfo[level]
					          + "' value='" + order + "'");
				}
				
				// plain bullet
				else if (pName.charAt(0) == '&') {
					pName = pName.substring(1);
					sBuf.append("<span");
					isBullet = true;
				}
				
				// radio
				else {
					sBuf.append("<input type='radio' name='R_" + levelInfo[level-1]
					          + "' value='" + order + "'");
				}


				// the passed in answer matches this one, check it
				if ( (ans!=null && ans.length>questNum
						&& foundAnswer(ans[questNum], String.valueOf(order)))
					|| (ans==null && order==1) )			// or no answer then check the first option
					sBuf.append(" checked");

				// paragraph in this option
				if (pName.indexOf(PGH_NAME) != -1)
					isParagraph = true;
				else
					isParagraph = false;
				sBuf.append(">&nbsp;&nbsp;");
			}
			else
			{
				// request user to enter a paragraph only, not MC ans.  This must be last ans.
				pName = pName.substring(1);
				sBuf.append("</td><td class='plaintext_big' valign='top'>");
				if (order > 1) sBuf.append("<br>");
				isParagraph = true;
				isLastAns = true;		// no MC answer after this.
				levelInfo[level] += ".0";	// 2.1.0  (use this is indicate it is not an MC ans for post_q_respond.jsp)
			}

			if (summaryB!=null && pName.indexOf(NUM_NAME)!=-1)
			{
				// has a numeric input field for this answer: add the sum value place holder in summary
				summaryB.append(quest.DELIMITER2 + "0");	// initialize sum value to 0
			}

			// setup user input field names: replace "NUM_NAME'>"
			ansStr = END_BLKT;
			if (ans!=null && level>0 && ans.length>questNum
					&& (foundAnswer(ans[questNum], String.valueOf(order)) || isLastAns) )
			{
				// the passed in answer matches this one
				// put the value into the input field if there is one
				if (pName.indexOf(NUM_NAME)!=-1 || pName.indexOf(STR_NAME)!=-1)
					ansStr = "' value='" + inputArr[questNum][choiceNum] + "'>";
				else if (isParagraph)
				{
					if (isLastAns)
					{
						if (inputArr[questNum][quest.MAX_CHOICES] != null)
							choiceNum = quest.MAX_CHOICES;	// that's where q_respond.jsp puts the last comment
						else {
							// q_respond.jsp stored last comment in the choiceNum location
							try {choiceNum = Integer.parseInt(ans[questNum]) - 1;}
							catch (Exception e) {choiceNum = quest.MAX_CHOICES;}
						}
					}

					s = inputArr[questNum][choiceNum];
					if (s == null) s = "";
					ansStr = END_BLKT + s;
				}
			}
			pName = pName.replaceAll(NUM_NAME+END_BLKT, "N_" + levelInfo[level] + ansStr);		// number field: N_1.2
			pName = pName.replaceAll(STR_NAME+END_BLKT, "S_" + levelInfo[level] + ansStr);		// string input: S_1.1
			pName = pName.replaceAll(PGH_NAME+END_BLKT, "P_" + levelInfo[level] + ansStr);		// paragraph: P_1.3

			if (level <= 0) sBuf.append("<b>" + pName + "</b>");
			else sBuf.append(pName);
			
			if (isBullet) sBuf.append("</span>");
			
			sBuf.append("</td></tr>");

			if (level <= 0)
				sBuf.append("<tr><td colspan='2'><img src='../i/spacer.gif' height='5' /></td></tr>");

		}
		sBuf.append("</table></td></tr>");
		sBuf.append("</table>");

		return sBuf.toString();
	}	// END: printQuest()


	// output HTML string for the questionnaire
	// this is very similiar to printQuest, just that this prints one or all the answers
	// to print 1 person's answer, pass ans and inputArr of that user (null if print summary)
	// to print a summary, ignore ans and inputArr, pass in numOfUsers, ansUidArr and inputAllArr
	// one possible enhancement is to pass in a 1D array containing all the users' fullName
	public static String printAnswer(
			PstUserAbstractObject pstuser,
			Vector rAgenda,				// the questions
			String [] ans,				// choice answer from selected user (can be null)
			String [][] inputArr,		// input from selected user (can be null)
			// the following params only for Summary
			String qidS,				// quest id
			int numOfUsers,				// total users responding to the quest
			int [][][] ansUidArr,		// array of uid that pick each question and choice
			String [][][] inputAllArr)	// array of input for each question and choice
		throws PmpException
	{
		// when the quest is first constructed, I will pass in a summary StringBuffer and
		// get the initial summary string back.
		StringBuffer sBuf = new StringBuffer(1024);
		String[] levelInfo = new String[10];
		boolean isParagraph = false, isNumber, isText, isLastAns = false;
		int questNum=0, choiceNum=0;
		int uid, ct;
		int [] ids;
		String s, ansStr, name, nameList, ansDateS, detailedStr;
		StringBuffer tempBuf;
		user u;
		boolean bShowSummary = (ansUidArr != null);
		boolean isBullet;
		Hashtable rTask;

		answerManager aMgr = answerManager.getInstance();
		SimpleDateFormat df1 = new SimpleDateFormat ("MM/dd/yy (EEE) hh:mm a");

		int i = 0;
		
		// check to see if there is a Beginning Statement
		while (rAgenda.size() > i) {
			rTask = (Hashtable)rAgenda.elementAt(i);
			s = ((String)rTask.get("Name")).trim();
			if (s.startsWith("-")) {
				s = s.substring(1).trim();				// skip the "-"
				sBuf.append("<tr><td colspan='2'><img src='../i/spacer.gif' height='15' /></td></tr>");
				sBuf.append("<tr><td colspan='2'  class='plaintext_big' valign='top' width='10'>");
				sBuf.append(s);
				sBuf.append("</td></tr>");
				
				i++;			// skip one task
				continue;
			}
			break;
		}
		

		for(; i < rAgenda.size(); i++)
		{
			rTask = (Hashtable)rAgenda.elementAt(i);
			String pName = (String)rTask.get("Name");
			Integer pLevel = (Integer)rTask.get("Level");
			Integer pOrder = (Integer)rTask.get("Order");

			int level = pLevel.intValue();
			int order = pOrder.intValue();

			int width = 10 + 22 * level;
			order++;
			isBullet = false;
			
			if (level == 0)
			{
				levelInfo[level] = String.valueOf(order);
				isLastAns = false;
				isParagraph = false;
				questNum = order - 1;			// question# starts from 0
			}
			else
			{
				if (isLastAns) continue;		// ignore the other multiple choice behind this
				levelInfo[level] = levelInfo[level - 1] + "." + order;
				choiceNum = order - 1;			// choice# starts from 0
			}

			// -- list the table of agenda items
			if (level <= 0)
				sBuf.append("<tr><td colspan='2'><img src='../i/spacer.gif' height='15' /></td></tr>");

			sBuf.append("<tr><td class='plaintext_big' valign='top' width='10'><img src='../i/spacer.gif' width='" + width + "' height='0' border='0'>");
			isNumber = isText = false;
			if (level <= 0)
			{
				// top level: this is the question
				sBuf.append(levelInfo[level]);
				sBuf.append("</td>");
				sBuf.append("<td class='plaintext_big' valign='top'>");
			}
			else if (pName.indexOf(PGH_NAME)==-1 || pName.charAt(0)!='-')
			{
				// radio or checkbox
				// the multiple choice or option questions (radio): R_1, R_2, etc.
				// checkbox: C_1, C_2, etc
				// answer starts from 1, 2, 3, ...
				sBuf.append("</td><td class='plaintext_big' valign='top'>");

				// checkbox (lines denoted by "*@")
				if (pName.charAt(0) == '@') {
					pName = pName.substring(1);
					sBuf.append("<input type='checkbox' name='C_" + levelInfo[level]
					          + "' value='" + order + "'");
				}
				
				// bullet
				else if (pName.charAt(0) == '&') {
					pName = pName.substring(1);
					sBuf.append("<span ");
					isBullet = true;
				}

				// radio
				else {
					sBuf.append("<input type='radio' name='R_" + levelInfo[level-1]
					          + "' value='" + order + "'");
				}


				// the passed in answer matches this one, check it
				if (ans!=null && ans.length>questNum
						&& foundAnswer(ans[questNum], String.valueOf(order)) )
					sBuf.append(" checked");

				sBuf.append(" disabled");	// this is just showing, not asking for input


//				sBuf.append("</td><td class='plaintext_big' valign='top'>");
//				sBuf.append("<input type='radio' name='R_" + levelInfo[level-1] + "' value='" + order + "'");

//				if (ans!=null && ans.length>questNum && ans[questNum]==order)		// the passed in answer matches this one, check it
//					sBuf.append(" checked");
//				sBuf.append(" disabled");					// this is just showing, not asking for input

				if (pName.indexOf(PGH_NAME) != -1)
					isParagraph = true;
				else
				{
					isParagraph = false;
					if (pName.indexOf(NUM_NAME) != -1)
						isNumber = true;
					else if (pName.indexOf(STR_NAME) != -1)
						isText = true;
				}
				sBuf.append(">&nbsp;&nbsp;");
			}
			else
			{
				// request user to enter a paragraph only, not MC ans.  This must be last ans.
				pName = pName.substring(1);								// cut the beginning "-"
				pName = pName.replace("textarea", "textareaX");			// hide the input box for showing answer
				sBuf.append("</td><td class='plaintext' valign='top'>");
				if (order > 1) sBuf.append("<br>");
				isParagraph = true;
				isLastAns = true;		// no MC answer after this.
				levelInfo[level] += ".0";	// 2.1.0  (use this is indicate it is not an MC ans for post_q_respond.jsp)
			}
			//System.out.println("----- "+levelInfo[level]);
			//System.out.println("parag="+isParagraph);

			// setup user input field names: replace "NUM_NAME'>"
			ansStr = END_BLKT;
			if (ans!=null && level>0 && ans.length>questNum
					&& (foundAnswer(ans[questNum], String.valueOf(order)) || isLastAns) )
			{
				// the passed in answer matches this one
				// put the value into the input field if there is one
				if (isNumber || isText)
					ansStr = "' value='" + inputArr[questNum][choiceNum] + END_BLKT;	//"' disabled>";
				else if (isParagraph)
				{
					if (isLastAns)
					{
						//System.out.println("*** isLast ans");
						//System.out.println("   inputArr[questNum][quest.MAX_CHOICES]="+inputArr[questNum][quest.MAX_CHOICES]);
						if (inputArr[questNum][quest.MAX_CHOICES] != null) {
							choiceNum = quest.MAX_CHOICES;	// that's where q_respond.jsp puts the last comment
						}
						else {
							// q_respond.jsp stored last comment in the choiceNum location
							// ECC: fix bug when ans[questNum] is not numeric value
							try {choiceNum = Integer.parseInt(ans[questNum]) - 1;}
							catch (Exception e) {choiceNum = quest.MAX_CHOICES;}
						}
					}
					
					//System.out.println("choiceNum="+choiceNum);
					s = inputArr[questNum][choiceNum];
					if (s==null) s = "";
					else s = s.replaceAll("\n", "<br>");
					ansStr = END_BLKT + s;
				}
			}

			pName = pName.replaceAll(NUM_NAME+END_BLKT, "N_" + levelInfo[level] + ansStr);		// number field: N_1.2
			pName = pName.replaceAll(STR_NAME+END_BLKT, "S_" + levelInfo[level] + ansStr);		// string input: S_1.1
			pName = pName.replaceAll(PGH_NAME+END_BLKT, "P_" + levelInfo[level] + ansStr);		// paragraph: P_1.3

			if (level <= 0) sBuf.append("<b>" + pName + "</b>");
			else sBuf.append(pName);
			
			if (isBullet) sBuf.append("</span>");
			
			sBuf.append("</td></tr>");
			
			
			//System.out.println("quest #"+ questNum+ ", choice #"+choiceNum);
			if (bShowSummary && level>0)
			{
				// put summary info for this choice answer
				sBuf.append("<tr><td colspan='2'><img src='../i/spacer.gif' height='5' /></td></tr>");
				sBuf.append("<tr><td></td><td class='plaintext'><blockquote>");	// OPEN a choice answer
				double totalNumInput = 0.0;
				tempBuf = new StringBuffer();
				detailedStr = "<br><a href='javascript:showDetailAns(" + questNum + ", " + choiceNum + ");'>Show details ...</a>"
						+ "<div id='detailAns_" + questNum + "-" + choiceNum + "' style='display:none;'>";
				nameList = "<table border='0' cellspacing='0' cellpadding='0'>";
				ct = 0;

				for (int j=0; j<numOfUsers; j++)
				{
					if (ansUidArr.length <= questNum) break;
					uid = ansUidArr[questNum][choiceNum][j];
					
					//System.out.println("ansUidArr["+questNum+"]["+choiceNum+"]["+j+"] = "+ uid);
					if (isLastAns && uid==0)
						uid = ansUidArr[questNum][quest.MAX_CHOICES][j];	// uid in MC before, this islastAns
					//System.out.println("  Final ansUidArr["+j+"] = "+ uid);
					if (uid <= 0) continue;					// this user didn't choose this answer
					try {u = (user)uMgr.get(pstuser, uid);}
					catch (PmpException e) {continue;}
					name = u.getFullName();

					// need to check for last comment
					int tempChoiceNum = choiceNum;
					if (isNumber || isText || isParagraph)
					{
						if (isLastAns)
						{
							//System.out.println("---- lastAns:");
							//System.out.println("   inputAllArr["+questNum+"][max]["+j+"]="+ inputAllArr[questNum][quest.MAX_CHOICES][j]);
							if (inputAllArr[questNum][quest.MAX_CHOICES][j] != null)
								tempChoiceNum = quest.MAX_CHOICES;
						}
						s = inputAllArr[questNum][tempChoiceNum][j];
						//System.out.println("   text input["+questNum+"]["+tempChoiceNum+"]["+j+"]: "+s);
						if (isNumber)
							totalNumInput += Double.parseDouble(s);
						else if (isParagraph || isText)
						{
							// output the text input of this user
							// John Smith: this is a good thing, etc., etc.
							if (s==null || s.length()<=0)
								continue;					// user didn't give a text input
							if (isParagraph) s = s.replaceAll("\n", "<br>");	// line breaks
						}

						// display this user's numeric or text input
						ids = aMgr.findId(pstuser, "TaskID='" + qidS + "' && Creator='" + uid + "'");
						ansDateS = df1.format((Date)aMgr.get(pstuser, ids[0]).getAttribute("LastUpdatedDate")[0]);
						tempBuf.append("<div><hr class='hr_short'/></div>");
						tempBuf.append("<div class='plaintext'>");
						tempBuf.append("<a href='q_answer.jsp?qid=" + qidS + "&uid=" + uid + "' class='listlink'>" + name + "</a>");
						tempBuf.append(" wrote on <span class='com_date'>" + ansDateS + "</span><br>");
						tempBuf.append(s);
						tempBuf.append("</div>");
					}

					// aggregate those who has submitted an answer
					if (ct%MAX_NUM == 0) nameList += "<tr>";
					nameList += "<td width='150'><a href='q_answer.jsp?qid=" + qidS + "&uid=" + uid + "' class='listlink'>" + name + "</a></td>";
					if (ct%MAX_NUM == MAX_NUM-1) nameList += "</tr>";
					ct++;			// one more person choose this answer
				}	// END: for the number of users
				
				if (ct%MAX_NUM != 0) nameList += "</tr>";
				nameList += "</table>";

				// handle the numeric input
				if (ct <= 0)
				{
					if (isLastAns)
						s = "No one responds to this question.";
					else
					s = "No one chooses this answer.";
				}
				else if (ct == 1)
				{
					if (isLastAns)
						s = "<b>1</b> person responds to this question.";
					else
					s = "<b>1</b> person chooses this answer.";
				}
				else
				{
					if (isLastAns)
						s = "<b>" + ct + "</b> people respond to this question.";
					else
					s = "<b>" + ct + "</b> people choose this answer.";
				}
				if (isNumber)
					s += " Total for the input field = <b>" + totalNumInput + "</b>";
				if (nameList.length() > 0)
					s += nameList;

				if (tempBuf.length()>0)
				{
					tempBuf.insert(0, detailedStr);
					tempBuf.append("</div>");
				}
				tempBuf.insert(0, s);								// summary of this answer at the head
				sBuf.append(tempBuf);
				sBuf.append("<hr class='evt_hr' />");				// partition a choice answer
				sBuf.append("</blockquote></td></tr>");				// CLOSE for a choice answer
			}	// END: bShowSummary

			if (level <= 0)
				sBuf.append("<tr><td colspan='2'><img src='../i/spacer.gif' height='5' /></td></tr>");

		}
		sBuf.append("</table></td></tr>");
		sBuf.append("</table>");

		return sBuf.toString();
	}	// END: printAnswer()

	public static void parseAns(String [] sa, String [] ans, String [][]inputArr)
		throws PmpException
	{
		int totalQuestion = sa.length, num;
		String [] sa1;
		String [] saAnswer;
		String s;
		for (int i=0; i<totalQuestion; i++)
		{
			// for each question, there might be numeric/text input
			// sa is the answer string to a question
			// e.g. 3::one choice$@$5::another choice ...

			saAnswer = sa[i].split("\\$@\\$");
			for (int j=0; j<saAnswer.length; j++) {

				// saAnswer[j] is one choice of answer in a question  (3::This is good)
				sa1 = saAnswer[j].split(quest.DELIMITER);

				// note for paragraph w/o a multi-choice, the answer is just text e.g. (This is good)
				// now we also support in MC question, allow last comment as a paragraph
				// in this case, answer looks like this 3::steak::last comment is here

				num = 0;
				try {num = Integer.parseInt(sa1[0]);}
				catch (Exception e) {
					// just a string
					inputArr[i][quest.MAX_CHOICES] = sa1[0];
					continue;
				}
				if (ans[i] == null) {
					ans[i] = sa1[0];
				}
				else {
					ans[i] += "," + sa1[0];
				}
				if (sa1.length > 1)
				{
					inputArr[i][num-1] = sa1[1];			// the numeric/string/paragraph input
				}
				if (sa1.length > 2) {
					inputArr[i][quest.MAX_CHOICES] = sa1[2];// put last comment here
				}

			}	// END: for each choice in an answer
		}	// END: for each question
	}

	public static void locateInputField(Vector rAgenda, boolean [][] inputFld)
	{
		// check each answer of each question to see if it has an input field
		int questNum=0, choiceNum;
		String pName;
		int level, order;
		for(int i = 0; i < rAgenda.size(); i++)
		{
			Hashtable rTask = (Hashtable)rAgenda.elementAt(i);
			level = ((Integer)rTask.get("Level")).intValue();
			order = ((Integer)rTask.get("Order")).intValue();

			if (level == 0)
			{
				questNum = order;				// question# starts from 0
			}
			else
			{
				if (inputFld.length <= questNum) continue;
				choiceNum = order;				// choice# starts from 0
				pName = (String)rTask.get("Name");
				if (pName.indexOf(NUM_NAME) != -1
						|| pName.indexOf(STR_NAME) != -1
						|| pName.indexOf(PGH_NAME) != -1)
					inputFld[questNum][choiceNum] = true;
				else
					inputFld[questNum][choiceNum] = false;
			}
		}
	}

	public static boolean foundAnswer(String choices, String numS)
	{
		if (choices==null || numS==null) return false;

		int num = Integer.parseInt(numS);
		String [] sa = choices.split(",");
		for (int i=0; i<sa.length; i++) {
			int thisNum = Integer.parseInt(sa[i]);
			if (num == thisNum) {
				return true;
			}
		}
		return false;
	}
}