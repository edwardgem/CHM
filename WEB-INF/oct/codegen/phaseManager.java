//
//  Copyright (c) 2004, eGuanxi, Inc.  All rights reserved.
//
//	Licensee of FastPath (tm) is authorized to change, distribute
//	and resell this source file and the compliled object file,
//	provided the copyright statement and this statement is included
//	as header.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   phaseManager.java
//  Author: FastPath CodeGen Engine
//  Date:   03.18.2004
//  Description:
//    This is a class that represent the container of phase classes.
//
//  Modification:
//		@030904ECC	Created template file for class representation of OMM Organization.
//
/////////////////////////////////////////////////////////////////////
//
// phaseManager.java : For phase object container manipulation
//

package oct.codegen;
import java.util.ArrayList;

import oct.omm.client.OmsMember;
import oct.omm.client.OmsOrganization;
import oct.omm.client.OmsSession;
import oct.omm.common.OmsException;
import oct.omm.common.OmsObList;
import oct.omm.common.OmsObject;
import oct.pmp.exception.PmpAddAttributeException;
import oct.pmp.exception.PmpAttributeNotFoundException;
import oct.pmp.exception.PmpCommitObjectException;
import oct.pmp.exception.PmpDeleteObjectException;
import oct.pmp.exception.PmpException;
import oct.pmp.exception.PmpIllegalTypeException;
import oct.pmp.exception.PmpInternalException;
import oct.pmp.exception.PmpInvalidAttributeException;
import oct.pmp.exception.PmpManagerCreationException;
import oct.pmp.exception.PmpObjectCreationException;
import oct.pmp.exception.PmpObjectNotFoundException;
import oct.pst.PstAbstractObject;
import oct.pst.PstSystem;
import oct.pst.PstUserAbstractObject;
import util.Util;

 /**
  *
  * <b>General Description:</b>  phaseManager extends PstManager.  This class
  * manages all phase objects such as creating, retrieving, saving, and
  * deleting phase objects.
  *
  * phaseManager can only instantiated through the getInstance() method.
  *
  *
  * <b>Class Dependencies:</b>
  *   oct.codegen.phase
  *   oct.pst.PstUserAbstractObject
  *   oct.pst.PstUserManager
  *   oct.pst.PstAbstractObject
  *   oct.pst.PstManager
  *
  *
  * <b>Miscellaneous:</b> None.
  *
  */


public class phaseManager extends oct.pst.PstManager

{
    public static final String NAME = "phase";     // The orgname of Object phase
    public static final String CLASSNAME = "oct.codegen.phase";     // The className of Object phase

    private static phaseManager manager = null;


    /**
     * Construct an empty phase object
     * @param userObj A PstUserAbstractObject.
     */
    private phaseManager(PstUserAbstractObject userObj)
        throws PmpManagerCreationException
    {
        super(userObj, NAME, CLASSNAME);
    }

    /**
     * Instantiates a phaseManager object.
     * @return A phaseManager.
     */
    public static phaseManager getInstance()
        throws PmpManagerCreationException, PmpInternalException
    {
        if(manager == null)
        {
            manager = new phaseManager(PstSystem.getInstance());
        }
        return manager;
    }//End getInstance


    /**
     * Create a new phase object.
     * @param userObj The PstUserAbstractObject who is requesting to create a phase.
     * @param type The type of phase to create.<br>
     * @param phaseName The name of the phase.
     *
     * @exception PmpObjectCreationException There was an error creating the phase.
     * @exception PmpIllegalTypeException The specified compnaytype is invalid.
     * @return The data object that was created.  An explicit cast is required to convert to a phase object.
     */
    public PstAbstractObject create(PstUserAbstractObject userObj, String phaseName)
        throws PmpIllegalTypeException, PmpObjectCreationException
    {
        return create(userObj.getSession(), phaseName);
    }//End create

    /**
     * Create a new phase object.
     * @param session An OmsSession.
     * @param type The type of phase to create.<br>
     * @param phaseName The name of the phase.
     * @exception PmpObjectCreationException There was an error creating the phase.
     * @exception PmpIllegalTypeException The specified phase type is invalid.
     * @return The data object that was created.  An explicit cast is required to convert to a phase object.
     */
    PstAbstractObject create(OmsSession session, String phaseName)
        throws PmpIllegalTypeException, PmpObjectCreationException
    {
        phase phase = null;
        if(phaseName == null || phaseName.length() == 0)
        {
            throw new PmpObjectCreationException("The phase name cannot be empty.");
        }

        try
        {

            phase = new phase(session,m_organization, phaseName);
            return phase;
        }
        catch(PmpException pe)
        {
            if(phase != null)
            {
                try
                {
                    delete(phase);
                }
                catch(Exception e1)
                {
                }
            }
            throw new PmpObjectCreationException("Error creating phase object:" + pe.toString());
        }
    }//End create


    /**
     * create creates a new user of the specified type
     * @param userObj - the user asking to create a user
     * @param type - the type of user to create (i.e. SELLER, BUYER_ADMIN, etc.)  see public static constants
     * @return PstUserAbstractObject - the created user
     * @exception PmpObjectCreationException - could not create the user in the databse
     * @exception PmpInternalException - could not create the user
     */
    public PstAbstractObject create(PstUserAbstractObject userObj, String memberName, String password)
    	throws PmpObjectCreationException, PmpInternalException
    {
		phase newUser = null;
		try
		{
			newUser = new phase(userObj, m_organization, memberName, password);
		}
		catch(PmpException e)
		{
			throw new PmpObjectCreationException("Cannot create new phase");
		}

		return newUser;
    }



    /**
     * create creates a new object with generated member name
     * @param userObj - the user asking to create a user
     * @return PstUserAbstractObject - the created user
     * @exception PmpObjectCreationException - could not create the user in the databse
     * @exception PmpInternalException - could not create the user
     */
    public PstAbstractObject create(PstUserAbstractObject userObj)
    	throws PmpObjectCreationException, PmpInternalException
    {
		phase newUser = null;
		try
		{
			newUser = new phase(userObj, m_organization);
		}
		catch(PmpException e)
		{
			throw new PmpObjectCreationException("Cannot create new phase");
		}

		return newUser;
    }




    /**
     *
     * Obtain a phase object from database.
     * @param userObj  PstUserAbstractObject requesting a phase object.
     * @param objectId Object id of the phase object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a phase object.
     */
    public PstAbstractObject get(PstUserAbstractObject userObj, int objectId)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(userObj.getSession(), objectId);
    }//End get

    /**
     *
     * Obtain a phase object from database.
     * @param session  An OmsSession.
     * @param objectId Object id of the phase object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a phase object.
     */
    PstAbstractObject get(OmsSession session, int objectId)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        try
        {
            OmsMember member = new OmsMember(session,objectId);
            if(member.getOrgId() != super.m_organization.getId())
            {
                throw new PmpObjectNotFoundException("Member not in phase organization.");
            }

            //Return a phase object
            return new phase(member);
        }
        catch(OmsException oe)
        {
            throw new PmpObjectNotFoundException(oe.toString());
        }
    }//End get

    /**
     *
     * Obtain a phase object from the database.
     * @param userObj  A PstUserAbstractObject.
     * @param objectName Object name of the phase object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a phase object.
     */
    public PstAbstractObject get(PstUserAbstractObject userObj, String objectName)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(userObj.getSession(),objectName);
    }//End get

    /**
     *
     * Obtain a phase object from the database.
     * @param session  An OmsSession.
     * @param objectName Object name of the phase object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a phase object.
     */
    PstAbstractObject get(OmsSession session, String objectName)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        try
        {
            OmsMember member = new OmsMember(session, super.m_organization, objectName);
            if(member.getOrgId() != super.m_organization.getId())
            {
                throw new PmpObjectNotFoundException("Member not in phase organization.");
            }
            //Return a phase object
            return new phase(member);
        }
        catch(OmsException oe)
        {
            throw new PmpObjectNotFoundException(oe.toString());
        }
    }//End get

    /**
     *
     * Obtain an array of phase objects based on a set of specified object ids.
     * @param userObj  PstUserAbstractObject requesting the phase objects.
     * @param objectIds Object ids in an int array of all phase objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a phase object.
     *   <b>NOTE:</b>  The arrays of phase will be sorted by object ids,
     *   NOT the order that the ids were specified
     */
    public PstAbstractObject [] get(PstUserAbstractObject userObj, int [] objectIds)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(userObj.getSession(), objectIds);
    }//End get

    /**
     *
     * Obtain an array of phase objects based on a set of specified object ids.
     * @param userObj  PstUserAbstractObject requesting the phase objects.
     * @param objectIds Object ids in an Integer array of all phase objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a phase object.
     *   <b>NOTE:</b>  The arrays of phase will be sorted by object ids,
     *   NOT the order that the ids were specified
     */
    public PstAbstractObject [] get(PstUserAbstractObject userObj, Object [] objectIds)
        throws PmpObjectNotFoundException, PmpInternalException
    {
		int count = objectIds.length;
		int [] ia = new int [count];
		for (int i=0; i<count; i++)
			ia[i] = ((Integer)objectIds[i]).intValue();
        return get(userObj.getSession(), ia);
    }//End get

    /**
     *
     * Obtain a Company object based on a set of phase ids.
     * Obtain an array of phase objects based on a set of specified object ids.
     * @param session  PstUserAbstractObject requesting the phase objects.
     * @param objectIds Object ids of all phase objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a phase object.
     *   <b>NOTE:</b>  The arrays of phase will be sorted by object ids,
     *   NOT the order that the ids were specified
     */
    PstAbstractObject [] get(OmsSession session, int [] objectIds)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        try
        {
            int count = objectIds.length;
            if(count <1)
            {
                    return new phase[0];
            }

            OmsOrganization org = super.m_organization.copyOrg(session);

            //Set up a list of OmsObject to pass to getMultiMembers
            OmsObList idList = new OmsObList(OmsObject.OMS_OBJECT_LST);
            for(int i=0; i<count; i++)
            {
                OmsObject obj = new OmsObject();  //Note: obj does not contain memname
                obj.setId(objectIds[i]);
                idList.add(obj);
            }

            OmsObList memList = org.getMultiMembers(idList);  //Get the multiple members
            int newCount = memList.size();

            phase [] result = new phase[newCount];

            for(int i=0; i<newCount; i++)
            {
                OmsMember member = (OmsMember) memList.get(i);
                //Return a phase object
                result[i] = new phase(member);

            }

            return result;
        }
        catch(OmsException oe)
        {
            throw new PmpObjectNotFoundException(oe.toString());
        }
    }//End get

    /**
     *
     * Obtain an array of phase objects based on a set of specified phase member names.
     * @param userObj  PstUserAbstractObject requesting the phase objects.
     * @param objectNames Object names of all phase objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a phase object.
     *   <b>NOTE:</b>  The arrays of phase will be sorted by object ids,
     *   NOT the order that the ids were specified
     */
    public PstAbstractObject [] get(PstUserAbstractObject userObj, String [] objectNames)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(userObj.getSession(), objectNames);
    }//End get

    /**
     *
     * Obtain an array of phase objects based on a set of specified phase member names.
     * @param session  PstUserAbstractObject requesting the phase objects.
     * @param objectNames Object names of all phase objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a phase object.
     *   <b>NOTE:</b>  The arrays of phase will be sorted by object ids,
     *   NOT the order that the ids were specified
     */
    PstAbstractObject [] get(OmsSession session, String [] objectNames)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        int count = objectNames.length;
        if(count <1)
        {
                    return new phase[0];
        }

        ArrayList result = new ArrayList();

        for(int i=0; i<count; i++)
        {
            try
            {
                result.add(get(session,objectNames[i]));
            }
            catch (PmpException pe)
            {
                continue;  //Skip bad objectNames
            }
        }
        int newCount = result.size();

        phase [] newResult = new phase[newCount];
        for(int i=0; i<newCount; i++)
        {
            newResult[i] = (phase) result.get(i);
        }

        return newResult;

    }//End get

    /**
     *
     * Delete the member from the database.
     * @param dataObject The phase object to delete permanently.
     * @exception PmpDeleteObjectException Could not delete the specified object.
     */
    public void delete(PstAbstractObject dataObject)
        throws PmpDeleteObjectException
    {
        ((phase)dataObject).delete();

    }//End delete

    /**
     *
     * Save the member to the database.
     * @param dataObject The phase object to save.
     * @exception PmpCommitObjectException Could not save the specified object.
     */
    public void commit(PstAbstractObject dataObject)
        throws PmpCommitObjectException
    {
        ((phase)dataObject).save();

    }//End commit

    /**
     *
     * Refresh the member. Currently, not implemented.
     * @param dataObject The phase object to refresh.
     */
    public void refresh(PstAbstractObject dataObject)
    {
        ((phase)dataObject).refresh();

    }//End refresh



    /**
     * Obtain a List of phase objects that belongs to the phase.
     *
     * @param userObj - PstUserAbstractObject requesting the phase objects.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An List of phase objects that is own by this user.
     *
     */
    public PstAbstractObject [] getAllphase(PstUserAbstractObject userObj)
        throws PmpObjectNotFoundException, PmpInternalException
    {
		String expr = "(om_acctname='%')";

		int id[] = this.findId(userObj.getSession(), expr);

		if (id == null)
			return null;

		PstAbstractObject objArray[] = this.get(userObj, id);

        return objArray;
    }
    
    /**
     * Obtains a list of phase that belongs to the project. 
     * 
     * @param pstuser
     * @param projectID
     * @return A sorted list of phases, no sub-phase is return.  See getSubPhases().
     */
    public PstAbstractObject [] getPhases(PstUserAbstractObject pstuser, String projectID) throws PmpException
    {
    	// only main phases has projectID, subphases has parentID instead
    	int[] phaseArr = findId(pstuser, phase.PROJECTID + "='"+projectID+"'");
    	PstAbstractObject [] objArr = get(pstuser, phaseArr);
    	// TODO: condition checking to make sure data are correct
    	// check for duplicate phase numbers etc...
    	Util.sortInteger(objArr, phase.PHASENUMBER);
    	return objArr;
    }
    
    /**
     * Obtains a list of subPhase that belongs to the phase. 
     * 
     * @param pstuser
     * @param phaseID
     * @return A sorted list of subPhase
     */
    public PstAbstractObject [] getSubPhases(PstUserAbstractObject pstuser, String phaseID) throws PmpException {
    	int [] phaseArr = findId(pstuser, phase.PARENTID+"='"+phaseID+"'");
    	PstAbstractObject [] objArr = get(pstuser, phaseArr);
    	// TODO: condition checking to make sure data are correct
    	// check for duplicate phase numbers etc...
    	Util.sortInteger(objArr, phase.PHASENUMBER);
    	return objArr;
    }
    
    public boolean hasSubPhases(PstUserAbstractObject pstuser, String phaseID) throws PmpException {
    	int [] phaseArr = findId(pstuser, phase.PARENTID+"='"+phaseID+"'");
    	PstAbstractObject [] objArr = get(pstuser, phaseArr);
    	if (objArr.length > 0)
    		return true;
    	else 
    		return false;
    }
    
    
    /**
     * Removes the current phase. Also removes any other sibling phases with
     * higher PhaseNumber. Assumes the phase object structure is correct. 
     * @param pstuser
     * @param phaseID
     * @return true - remove of extra phase object is okay; otherwise false
     * @throws PmpException
     */
    public boolean removePhases(PstUserAbstractObject pstuser, String phaseID) throws PmpException {
    	if (phaseID != null && phaseID.length() > 0) {
    		try {
	    		PstAbstractObject [] objArr;
	    		PstAbstractObject obj = get(pstuser, phaseID);
	    		Object [] array = obj.getAttribute(phase.PROJECTID);
	    		// Phase
	    		if (array[0] != null) {
	    			objArr = getPhases(pstuser, array[0].toString());
	    			array = obj.getAttribute(phase.PHASENUMBER);
	    			if (array[0] != null) {
	    				String phaseNumberS = array[0].toString();
	    				if (phaseNumberS.length() > 0) {
	    					int phaseNumber = Integer.parseInt(phaseNumberS);
	    					// phaseNumber starts from 1
	    					for (int i=phaseNumber-1; i<objArr.length; i++) {
								PstAbstractObject [] sObjArr = getSubPhases(pstuser, String.valueOf(objArr[i].getObjectId()));
								for (int j=0; j<sObjArr.length; j++) {
									delete(sObjArr[j]);
								}
	    						delete(objArr[i]);
	    					}
	    					return true;
	    				}
	    			}
	    			else {
	    				// corrupted data in db
	    				throw new PmpException();
	    			}
	    		}
	    		// SubPhase
	    		else {
	    			array = obj.getAttribute(phase.PARENTID);
		    		if (array[0] != null) {
		    			objArr = getSubPhases(pstuser, array[0].toString());
		    			array = obj.getAttribute(phase.PHASENUMBER);
		    			if (array[0] != null) {
		    				String phaseNumberS = array[0].toString();
		    				if (phaseNumberS.length() > 0) {
		    					int phaseNumber = Integer.parseInt(phaseNumberS);
		    					// phaseNumber starts from 1
		    					for (int i=phaseNumber-1; i<objArr.length; i++) {
		    						delete(objArr[i]);
		    					}
		    					return true;
		    				}
		    			}
		    			else {
		    				// corrupted data in db
		    				throw new PmpException();
		    			}
		    		}
	    		}
	    		// corrupted data in db
				throw new PmpException();
	    		
    		} catch (PmpException e) {
    			// bad phaseID
    			e.printStackTrace();
    		}
    	}
    	return false;
    }
    
    /**
     * Removes a single phase and shifts the remaining phases
     * @param pstuser
     * @param phaseID
     * @return
     * @throws PmpException
     */
    public boolean removePhase(PstUserAbstractObject pstuser, String phaseID) throws PmpException {
    	if (phaseID != null && phaseID.length() > 0) {
    		try {
	    		PstAbstractObject [] objArr;
	    		PstAbstractObject obj = get(pstuser, phaseID);
	    		Object [] array = obj.getAttribute(phase.PROJECTID);
	    		// Phase
	    		if (array[0] != null) {
	    			objArr = getPhases(pstuser, array[0].toString());
	    			array = obj.getAttribute(phase.PHASENUMBER);
	    			if (array[0] != null) {
	    				String phaseNumberS = array[0].toString();
	    				if (phaseNumberS.length() > 0) {
	    					int phaseNumber = Integer.parseInt(phaseNumberS);
	    					
	    					// Delete Subphases
	    					PstAbstractObject [] sObjArr = getSubPhases(pstuser, String.valueOf(objArr[phaseNumber-1].getObjectId()));
							for (int j=0; j<sObjArr.length; j++) {
								delete(sObjArr[j]);
							}
							delete(objArr[phaseNumber-1]); // delete the phase
							
	    					// Rearrange the phaseNumbers
	    					for (int i=phaseNumber; i<objArr.length; i++) { // phaseNumbers start from 1
	    						array = objArr[i].getAttribute(phase.PHASENUMBER);
	    						if (array[0] != null) {
	    							int newPhaseNumber = Integer.parseInt(array[0].toString())-1;
	    							objArr[i].setAttribute(phase.PHASENUMBER, Integer.valueOf(newPhaseNumber));
	    							commit(objArr[i]);
	    						}
	    						else {
	    							// corrupted data in db
	    							throw new PmpException();
	    						}
	    					}
	    					return true;
	    				}
	    			}
	    			else {
	    				// corrupted data in db
	    				throw new PmpException();
	    			}
	    		}
	    		// SubPhase
	    		else {
	    			array = obj.getAttribute(phase.PARENTID);
		    		if (array[0] != null) {
		    			objArr = getSubPhases(pstuser, array[0].toString());
		    			array = obj.getAttribute(phase.PHASENUMBER);
		    			if (array[0] != null) {
		    				String phaseNumberS = array[0].toString();
		    				if (phaseNumberS.length() > 0) {
		    					int phaseNumber = Integer.parseInt(phaseNumberS);
		    					delete(objArr[phaseNumber-1]); // remove the subphase
		    					
		    					// Rearrange the phaseNumbers
		    					for (int i=phaseNumber; i<objArr.length; i++) { // phaseNumbers start from 1
		    						array = objArr[i].getAttribute(phase.PHASENUMBER);
		    						if (array[0] != null) {
		    							int newPhaseNumber = Integer.parseInt(array[0].toString())-1;
		    							objArr[i].setAttribute(phase.PHASENUMBER, Integer.valueOf(newPhaseNumber));
		    							commit(objArr[i]);
		    						}
		    						else {
		    							// corrupted data in db
		    							throw new PmpException();
		    						}
		    					}
		    					return true;
		    				}
		    			}
		    			else {
		    				// corrupted data in db
		    				throw new PmpException();
		    			}
		    		}
	    		}
	    		// corrupted data in db
				throw new PmpException();
	    		
    		} catch (PmpException e) {
    			// bad phaseID
    			e.printStackTrace();
    		}
    	}
    	return false;
    }
    
    //private 
    
    /**
     * Receives two sorted arrays of user objects and removes duplicated names from the dupArrList.
     * The duplicates will be set to null
     * @param mainObjArr Sorted user object[]
     * @param dupObjArr Sorted user array list
     * @throws PmpException
     */
    public void removeDuplicateInt(Object [] mainObjArr, ArrayList dupArrList) throws PmpException {
    	if (mainObjArr != null && mainObjArr.length > 0
    			&& dupArrList != null && dupArrList.size() > 0) {    		
	    	StringBuffer sb = new StringBuffer();
    		int mainIdx = 0;
	    	int dupIdx = 0;
	    	int compare = 0;
	    	String mainName, dupName;
	    	user mainU = null;
	    	user dupU = null;
	    	int mainLength = mainObjArr.length;
	    	int dupLength = dupArrList.size();
	    	while ( mainIdx < mainLength && dupIdx < dupLength) {
	    		if (mainObjArr[mainIdx] == null ) { mainIdx++; continue;}
	    		if (dupArrList.get(dupIdx) == null) { dupIdx++; continue;}
	    		mainU = (user)mainObjArr[mainIdx];
	    		dupU = (user)dupArrList.get(dupIdx);
	    		
	    		sb.append(mainU.getAttribute("FirstName")[0]);
	    		sb.append(mainU.getAttribute("LastName")[0]);
	    		mainName = sb.toString();
	    		sb.delete(0, sb.length());
	    		
	    		sb.append(dupU.getAttribute("FirstName")[0]);
	    		sb.append(dupU.getAttribute("LastName")[0]);
	    		dupName = sb.toString();
	    		sb.delete(0, sb.length());
	    		
	    		compare = mainName.compareTo(dupName);
	    		if (compare < 0) {
	    			mainIdx++;
	    		}
	    		else if (compare > 0) {	    			
	    			dupIdx++;
	    		}
	    		else {
	    			dupArrList.set(dupIdx, null);
	    			mainIdx++;
	    			dupIdx++;
	    		}
	    	}
    	}
    }
    
    /**
     * Receives two sorted arrays of user objects and removes duplicated names from the dupObjArr.
     * The duplicates will be set to null.
     * @param mainObjArr
     * @param dupObjArr
     * @throws PmpException
     */
    public void removeDuplicateInt(Object [] mainObjArr, Object [] dupObjArr) throws PmpException {
    	if (mainObjArr != null && mainObjArr.length > 0
    			&& dupObjArr != null && dupObjArr.length > 0) {
    		StringBuffer sb = new StringBuffer();
	    	int mainIdx = 0;
	    	int dupIdx = 0;
	    	int compare = 0;
	    	String mainName, dupName;
	    	user mainU = null;
	    	user dupU = null;
	    	int mainLength = mainObjArr.length;
	    	int dupLength = dupObjArr.length;
	    	while ( mainIdx < mainLength && dupIdx < dupLength) {
	    		if (mainObjArr[mainIdx] == null ) { mainIdx++; continue;}
	    		if (dupObjArr[dupIdx] == null) { dupIdx++; continue;}
	    		mainU = (user)mainObjArr[mainIdx];
	    		dupU = (user)dupObjArr[dupIdx];
	    		
	    		sb.append(mainU.getAttribute("FirstName")[0]);
	    		sb.append(mainU.getAttribute("LastName")[0]);
	    		mainName = sb.toString();
	    		sb.delete(0, sb.length());
	    		
	    		sb.append(dupU.getAttribute("FirstName")[0]);
	    		sb.append(dupU.getAttribute("LastName")[0]);
	    		dupName = sb.toString();
	    		sb.delete(0, sb.length());
	    		
	    		compare = mainName.compareTo(dupName);
	    		if (compare < 0) {
	    			mainIdx++;
	    		}
	    		else if (compare > 0) {
	    			dupIdx++;
	    		}
	    		else {
	    			dupObjArr[dupIdx] = null;
	    			mainIdx++;
	    			dupIdx++;
	    		}
	    	}
    	}
    }
    
    /**
     * Expands phase lists and extracts duplicate users from optIds. It will compare between manIds and optIds 
     * for duplicate users and remove them from optIds.
     * @param pstuser
     * @param manIds 	A string of sorted users by id split with ; This string should have gone through
     * 					the removeDuplicate(pstuser, ids) method.
     * @param optIds	A string of phases and Users seperated by ;
     * @return A string of user ids separated by ;
     * @throws PmpException
     */
    public String [] removeDuplicateFromOptIds(PstUserAbstractObject pstuser, String [] manIds, String [] optIds) throws PmpException {
    	int manIdx = 0;
    	int optIdx = 0;
    	int compare = 0;
    	
    	if (manIds != null && manIds.length > 0 && 
    			optIds != null && optIds.length > 0) {
	    	int nullCount = 0;
	    	int manLen = manIds.length;
	    	int optLen = optIds.length;
	    	
	    	// remove duplicates from optIdx
	    	while (manIdx < manLen && optIdx < optLen) {
	    		compare = manIds[manIdx].compareTo(optIds[optIdx]);
	    		if (compare < 0)
	    			manIdx++;
	    		else if (compare > 0)
	    			optIdx++;
	    		// Equal. Remove from optSA
	    		else {
	    			optIds[optIdx] = null;
	        		manIdx++;
	        		optIdx++;
	        		nullCount++;
	    		}
	    	}
	    	
	    	if (nullCount > 0) {
	    		String [] strArr = new String[optLen-nullCount];
	    		int i = 0;
		    	for (optIdx = 0; optIdx < optLen; optIdx++) {
		    		if(optIds[optIdx] != null) {
		    			strArr[i] = optIds[optIdx];
		    			i++;
		    		}
		    	}
		    	return strArr;
	    	}
	    }
    	return optIds;
    }

    /**
     * Add a dynamic attribute to the purchase order object definition
     * @param <b> userObj </b> user object
     * @param <b> attObject </b> object contains information of the attribute to be added
     * @return a list of PstAttributeObject objects
     * @exception PmpAddAttributeException could not add attribute.
     * @exception PmpInternalException internal errors
     */
    public void addAttribute(PstUserAbstractObject userObj, String attributeName, boolean required)
        throws PmpInternalException
    {
        super.addAttribute(userObj, attributeName, required);
    }

    /**
     * Remove an attribute
     * @param <b> userObj </b> user object
     * @param <b> attname </b> name of the attribute to be deleted
     * @exception PmpAttributeNotFoundException attribute cannot be found
     * @exception PmpInternalException internal error.
     */
    public void removeAttribute(PstUserAbstractObject userObj, String attName)
    	throws PmpInternalException, PmpAttributeNotFoundException, PmpInvalidAttributeException
    {
        super.removeAttribute(userObj,attName);
    }

    /**
     * Return a PstAttributeObject that contains information of the given attribute name,
     * including system and dynmaic attribute.
     * @param <b> userObj </b> user object
     * @param <b> attName </b> name of the attribure to be returned
     * @return a PstAttributeObject object
     * @exception PmpAttributeNotFoundException attribute cannot be found
     * @exception PmpInternalException internal error.

    public PstAttributeObject getAttribute(PstUserAbstractObject userObj, String attName)
        throws PmpAttributeNotFoundException, PmpInternalException
    {
        PstAttributeObject attribData = super.getAttribute(userObj,attName);
        if(attribData == null)
        {
            throw new PmpAttributeNotFoundException("Attribute does not exist.");
        }
        else
        {
            return attribData;
        }

    }//End getAttribute
*/

    /**
     * Determine whether an attribute name is valid.
     * @param attributeName The name of the attribute.
     * @return A boolean indicating whether the attribute name is valid.
     */
    public boolean isAttributeValid(String attributeName)
    {
        return super.isAttributeValid(attributeName);
    }


    /**
     * Determine whether an attribute is valid and whether the
     * value for the attribute is of the correct type.
     * A valid attribute with a null value will return true.
     * @param attributeName The name of the attribute.
     * @param val The value of the attribute to verify. This can be an array of Object values,
     * but not an array of primitive values.  It will always fail with an array of primitive values.
     * @exception PmpInternalException An internal error occurred.
     * @exception PmpInvalidAttributeException An attribute name is invalid.
     * @return Return whether the attribute value is valid based on whether
     * there is such an attribute and whether the type matched.
     */
    public boolean isValueValid(String attributeName, Object val)
        throws PmpInternalException, PmpInvalidAttributeException
    {
        return super.isValueValid(attributeName,val);
    }// End isValueValid


    /**
     * Determine whether an attribute id is valid.
     * @param attributeId The id of the attribute.
     * @return A boolean indicating whether the attribute id is valid.
     */
    public boolean isAttributeValid(int attributeId)
    {
        return super.isAttributeValid(attributeId);
    }

    /**
     * Determine if the attribute is required.
     * @param obj A PstAbstractObject to verfiy an attribute against.
     * @attributeId The id of the attribute.
     * @return A boolean indicating whether the attribute is required for this PstAbstractObject.
     */
    public boolean isAttributeRequired(PstAbstractObject obj, int attributeId)
        throws PmpInvalidAttributeException, PmpException
    {
        return super.isAttributeRequired(obj, attributeId);

    }//End isAttributeRequired

    /**
     * Determine if the attribute is required.
     * @param obj A PstAbstractObject to verfiy an attribute against.
     * @attributeName The name of the attribute.
     * @return A boolean indicating whether the attribute is required for this PstAbstractObject.
     */
    public boolean isAttributeRequired(PstAbstractObject obj, String attributeName)
        throws PmpInvalidAttributeException, PmpException
    {
        return super.isAttributeRequired(obj,attributeName);
    }

    /**
     * Determine the if the attribute has multiple values.
     * @param attributeId The id of the attribute.
     * @return A boolean indicating whether the attribute can hold multiple values.
     */
    public boolean hasMultipleValues(int attributeId)
        throws PmpInvalidAttributeException
    {
        return super.hasMultipleValues(attributeId);
    }

    /**
     * Determine the if the attribute has multiple values.
     * @param attributeName The name of the attribute.
     * @return A boolean indicating whether the attribute can hold multiple values.
     */
    public boolean hasMultipleValues(String attributeName)
        throws PmpInvalidAttributeException
    {
        return super.hasMultipleValues(attributeName);
    }

    /**
     * Determine the attribute type from a given attribute id.
     * @param attributeId The id of the attribute.
     * @return The value type for the attribute. Possible values are: PstAbstractObject.STRING, PmpAbstractObject.INT, PmpAbstractObject.FLOAT, PmpAbstractObject.DATE, and PstAbstractObject.RAW.
     */
    public int getAttributeType(int attributeId)
        throws PmpInvalidAttributeException, PmpInternalException
    {
        return super.getAttributeType(attributeId);
    }

    /**
     * Determine the attribute type from a given attribute name.
     * @param attributeName The name of the attribute.
     * @return The value type for the attribute. Possible values are: PstAbstractObject.STRING, PmpAbstractObject.INT, PmpAbstractObject.FLOAT, PmpAbstractObject.DATE, and PstAbstractObject.RAW.
     */
    public int getAttributeType(String attributeName)
        throws PmpInvalidAttributeException, PmpInternalException
    {
        return super.getAttributeType(attributeName);
    }

    /**
     * Retrieve the attribute's name given the attribute id.
     * @param attributeId The id of the attribute.
     * @exception PmpInvalidAttributeException The specified attribute id does not exist.
     * @return The String name of the attribute.
     */
    public String getAttributeName(int attributeId)
        throws PmpInvalidAttributeException
    {
        return super.getAttributeName(attributeId);
    }

    /**
     * Retrieve the attribute's id given the attribute name.
     * @param attributeName The name of the attribute.
     * @exception PmpInvalidAttributeException The specified attribute name does not exist.
     * @return The id of the attribute.
     */
    public int getAttributeId(String attributeName)
        throws PmpInvalidAttributeException
    {
        return super.getAttributeId(attributeName);
    }

    /**
     * Obtain all attribute names of this organization.
     * @return An array of all the attribute names for the manager.
     */
    public String [] getAllAttributeNames()
    {
        return super.getAllAttributeNames();
    }

    /**
     * Obtain all attribute ids of this organization.
     * @return An array of all the attribute ids for the manager.
     */
    public int [] getAllAttributeIds()
    {
        return super.getAllAttributeIds();
    }


}//End class phaseManager
