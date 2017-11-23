//
//  Copyright (c) 2006, EGI Technologies, Inc.  All rights reserved.
//
//	Licensee of FastPath (tm) is authorized to change, distribute
//	and resell this source file and the compliled object file,
//	provided the copyright statement and this statement is included
//	as header.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   robotManager.java
//  Author: FastPath CodeGen Engine
//  Date:   06.16.2006
//  Desciption:
//    This is a class that represent the container of robot classes.
//
//  Modification:
//		@030904ECC	Created template file for class representation of OMM Organization.
//
/////////////////////////////////////////////////////////////////////
//
// robotManager.java : For robot object container manipulation
//

package oct.codegen;
import java.util.ArrayList;

import net.sf.json.JSONObject;
import net.sf.json.JSONSerializer;
import oct.omm.client.OmsMember;
import oct.omm.client.OmsOrganization;
import oct.omm.client.OmsSession;
import oct.omm.client.OmsWebservice;
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

 /**
  *
  * <b>General Description:</b>  robotManager extends PstManager.  This class
  * manages all robot objects such as creating, retrieving, saving, and
  * deleting robot objects.
  *
  * robotManager can only instantiated through the getInstance() method.
  *
  *
  * <b>Class Dependencies:</b>
  *   oct.codegen.robot
  *   oct.pst.PstUserAbstractObject
  *   oct.pst.PstUserManager
  *   oct.pst.PstAbstractObject
  *   oct.pst.PstManager
  *
  *
  * <b>Miscellaneous:</b> None.
  *
  */


public class robotManager extends oct.pst.PstManager

{
    public static final String NAME = "robot";     // The orgname of Object robot
    public static final String CLASSNAME = "oct.codegen.robot";     // The className of Object robot

    private static robotManager manager = null;


    /**
     * Construct an empty robot object
     * @param userObj A PstUserAbstractObject.
     */
    private robotManager(PstUserAbstractObject userObj)
        throws PmpManagerCreationException
    {
        super(userObj, NAME, CLASSNAME);
    }

    /**
     * Instantiates a robotManager object.
     * @return A robotManager.
     */
    public static robotManager getInstance()
        throws PmpManagerCreationException, PmpInternalException
    {
        if(manager == null)
        {
            manager = new robotManager(PstSystem.getInstance());
        }
        return manager;
    }//End getInstance


    /**
     * Create a new robot object.
     * @param userObj The PstUserAbstractObject who is requesting to create a robot.
     * @param type The type of robot to create.<br>
     * @param robotName The name of the robot.
     *
     * @exception PmpObjectCreationException There was an error creating the robot.
     * @exception PmpIllegalTypeException The specified compnaytype is invalid.
     * @return The data object that was created.  An explicit cast is required to convert to a robot object.
     */
    public PstAbstractObject create(PstUserAbstractObject userObj, String robotName)
        throws PmpIllegalTypeException, PmpObjectCreationException
    {
        return create(userObj.getSession(), robotName);
    }//End create

    /**
     * Create a new robot object.
     * @param session An OmsSession.
     * @param type The type of robot to create.<br>
     * @param robotName The name of the robot.
     * @exception PmpObjectCreationException There was an error creating the robot.
     * @exception PmpIllegalTypeException The specified robot type is invalid.
     * @return The data object that was created.  An explicit cast is required to convert to a robot object.
     */
    PstAbstractObject create(OmsSession session, String robotName)
        throws PmpIllegalTypeException, PmpObjectCreationException
    {
        robot robot = null;
        if(robotName == null || robotName.length() == 0)
        {
            throw new PmpObjectCreationException("The robot name cannot be empty.");
        }

        try
        {

            robot = new robot(session,m_organization, robotName);
            return robot;
        }
        catch(PmpException pe)
        {
            throw new PmpObjectCreationException("Error creating robot object:" + pe.toString());
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
		robot newUser = null;
		try
		{
			newUser = new robot(userObj, m_organization, memberName, password);
		}
		catch(PmpException e)
		{
			throw new PmpObjectCreationException("Cannot create new robot");
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
		robot newUser = null;
		try
		{
			newUser = new robot(userObj, m_organization);
		}
		catch(PmpException e)
		{
			throw new PmpObjectCreationException("Cannot create new robot");
		}

		return newUser;
    }




    /**
     *
     * Obtain a robot object from database.
     * @param userObj  PstUserAbstractObject requesting a robot object.
     * @param objectId Object id of the robot object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a robot object.
     */
    public PstAbstractObject get(PstUserAbstractObject userObj, int objectId)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(userObj.getSession(), objectId);
    }//End get

    /**
     *
     * Obtain a robot object from database.
     * @param session  An OmsSession.
     * @param objectId Object id of the robot object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a robot object.
     */
    PstAbstractObject get(OmsSession session, int objectId)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        try
        {
            OmsMember member = new OmsMember(session,objectId);
            if(member.getOrgId() != super.m_organization.getId())
            {
                throw new PmpObjectNotFoundException("Member not in robot organization.");
            }

            //Return a robot object
            return new robot(member);
        }
        catch(OmsException oe)
        {
            throw new PmpObjectNotFoundException(oe.toString());
        }
    }//End get

    /**
     *
     * Obtain a robot object from the database.
     * @param userObj  A PstUserAbstractObject.
     * @param objectName Object name of the robot object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a robot object.
     */
    public PstAbstractObject get(PstUserAbstractObject userObj, String objectName)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(userObj.getSession(),objectName);
    }//End get

    /**
     *
     * Obtain a robot object from the database.
     * @param session  An OmsSession.
     * @param objectName Object name of the robot object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a robot object.
     */
    PstAbstractObject get(OmsSession session, String objectName)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        try
        {
            OmsMember member = new OmsMember(session, super.m_organization, objectName);
            if(member.getOrgId() != super.m_organization.getId())
            {
                throw new PmpObjectNotFoundException("Member not in robot organization.");
            }
            //Return a robot object
            return new robot(member);
        }
        catch(OmsException oe)
        {
            throw new PmpObjectNotFoundException(oe.toString());
        }
    }//End get

    /**
     *
     * Obtain an array of robot objects based on a set of specified object ids.
     * @param userObj  PstUserAbstractObject requesting the robot objects.
     * @param objectIds Object ids in an int array of all robot objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a robot object.
     *   <b>NOTE:</b>  The arrays of robot will be sorted by object ids,
     *   NOT the order that the ids were specified
     */
    public PstAbstractObject [] get(PstUserAbstractObject userObj, int [] objectIds)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(userObj.getSession(), objectIds);
    }//End get

    /**
     *
     * Obtain an array of robot objects based on a set of specified object ids.
     * @param userObj  PstUserAbstractObject requesting the robot objects.
     * @param objectIds Object ids in an Integer array of all robot objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a robot object.
     *   <b>NOTE:</b>  The arrays of robot will be sorted by object ids,
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
     * Obtain a Company object based on a set of robot ids.
     * Obtain an array of robot objects based on a set of specified object ids.
     * @param session  PstUserAbstractObject requesting the robot objects.
     * @param objectIds Object ids of all robot objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a robot object.
     *   <b>NOTE:</b>  The arrays of robot will be sorted by object ids,
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
                    return new robot[0];
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

            robot [] result = new robot[newCount];

            for(int i=0; i<newCount; i++)
            {
                OmsMember member = (OmsMember) memList.get(i);
                //Return a robot object
                result[i] = new robot(member);

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
     * Obtain an array of robot objects based on a set of specified robot member names.
     * @param userObj  PstUserAbstractObject requesting the robot objects.
     * @param objectNames Object names of all robot objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a robot object.
     *   <b>NOTE:</b>  The arrays of robot will be sorted by object ids,
     *   NOT the order that the ids were specified
     */
    public PstAbstractObject [] get(PstUserAbstractObject userObj, String [] objectNames)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(userObj.getSession(), objectNames);
    }//End get

    /**
     *
     * Obtain an array of robot objects based on a set of specified robot member names.
     * @param session  PstUserAbstractObject requesting the robot objects.
     * @param objectNames Object names of all robot objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a robot object.
     *   <b>NOTE:</b>  The arrays of robot will be sorted by object ids,
     *   NOT the order that the ids were specified
     */
    PstAbstractObject [] get(OmsSession session, String [] objectNames)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        int count = objectNames.length;
        if(count <1)
        {
                    return new robot[0];
        }

        ArrayList <Object> result = new ArrayList<Object>();

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

        robot [] newResult = new robot[newCount];
        for(int i=0; i<newCount; i++)
        {
            newResult[i] = (robot) result.get(i);
        }

        return newResult;

    }//End get

    /**
     *
     * Delete the member from the database.
     * @param dataObject The robot object to delete permanently.
     * @exception PmpDeleteObjectException Could not delete the specified object.
     */
    public void delete(PstAbstractObject dataObject)
        throws PmpDeleteObjectException
    {
        ((robot)dataObject).delete();

    }//End delete

    /**
     *
     * Save the member to the database.
     * @param dataObject The robot object to save.
     * @exception PmpCommitObjectException Could not save the specified object.
     */
    public void commit(PstAbstractObject dataObject)
        throws PmpCommitObjectException
    {
        ((robot)dataObject).save();

    }//End commit

    /**
     *
     * Refresh the member. Currently, not implemented.
     * @param dataObject The robot object to refresh.
     */
    public void refresh(PstAbstractObject dataObject)
    {
        ((robot)dataObject).refresh();

    }//End refresh



    /**
     * Obtain a List of robot objects that belongs to the robot.
     *
     * @param userObj - PstUserAbstractObject requesting the robot objects.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An List of robot objects that is own by this user.
     *
     */
    public PstAbstractObject [] getAllrobot(PstUserAbstractObject userObj)
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

    /* Clone a robot object to a foreign node. The session of the foreign node is in foreignUser
     * Caller might want to call deployProgram() also.
	 * @see oct.pst.PstManager#cloneToDomain(oct.pst.PstUserAbstractObject, oct.pst.PstAbstractObject)
	 */
	@Override
	public int cloneToDomain(String uname, String pswd, String  wsURL, PstAbstractObject srcObj)
		throws PmpException {
		// clone a robot to another domain. This is to deploy the robot.
		// call Webservice to clone robot
		String jsonStr;
		
		OmsMember mem = srcObj.getMember();
		
		try {jsonStr = OmsWebservice.cloneBot(uname, pswd, wsURL, mem);}
		catch (Exception e) {throw new PmpException(e.getMessage());}
		
		JSONObject json = (JSONObject) JSONSerializer.toJSON(jsonStr);
		String botIdS = json.getString("botId");
		
		return Integer.parseInt(botIdS);
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
    

}//End class robotManager
