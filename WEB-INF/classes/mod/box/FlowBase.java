//
//  Copyright (c) 2009, EGI Technologies, Inc.  All rights reserved.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   FlowBase.java
//  Author: ECC
//  Date:   01/03/10
//  Description:
//		workflow interface
//  Modification:
//
/////////////////////////////////////////////////////////////////////
//
// FlowBase.java : interface for drawing flow map
//

package mod.box;

import oct.pst.PstFlowConstant;


public interface FlowBase

{
    //Private attributes
	
	// Public
	public static final String ST_ACTIVE	= "active";
	public static final String ST_COMMIT	= "commit";		// accept
	public static final String ST_ABORT		= "reject";
	
	public static final String TYPE_INSTANCE	= "instance";
	public static final String TYPE_DEFINITION	= "def";
	
	// XML step label
	public static final String ID		= PstFlowConstant.STEP_ID;
	public static final String NAME		= PstFlowConstant.STEP_NAME;
	public static final String STATE	= PstFlowConstant.STEP_STATE;
	public static final String CREATED	= PstFlowConstant.STEP_CREATED;		// created date
	public static final String EXPIRE	= PstFlowConstant.STEP_EXPIRE;		// expire date
	public static final String CREATOR	= PstFlowConstant.STEP_CREATOR;
	public static final String ASSIGN	= PstFlowConstant.STEP_ASSIGN;
	public static final String WORKBY	= PstFlowConstant.STEP_WORKBY;		// only filled at runtime
	public static final String INTOKEN	= PstFlowConstant.STEP_INTOKEN;
	public static final String OUTSTEP	= PstFlowConstant.STEP_OUTSTEP;
	public static final String INSTEP	= PstFlowConstant.STEP_INSTEP;
	public static final String LEVELH	= "levelH";
	public static final String LEVELV	= "levelV";
	
	public static final String TASKID		= "taskid";
	public static final String TASK_STATE	= "taskState";
	
	// assign to dummy means automatic step
	public static final String DUMMY	= "dummy";
	public static final String DUMAUTO	= "Automatic";


}//End interface FlowBase
