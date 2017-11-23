//
//  Copyright (c) 2005, EGI Technologies, Inc.  All rights reserved.
//
//	Licensee of FastPath (tm) is authorized to change, distribute
//	and resell this source file and the compliled object file,
//	provided the copyright statement and this statement is included
//	as header.
//
/////////////////////////////////////////////////////////////////////
//
//  File:   PepEmployeeManager.java
//  Author: FastPath CodeGen Engine
//  Date:   03.18.2003
//  Description:
//    This is a class that represent the container of PepEmployee classes.
//
//  Modification:
//		@03.18.2003aFCE File created by FastPath
//
/////////////////////////////////////////////////////////////////////
//
// PepEmployeeManager.java : For PepEmployee object container manipulation
//

package oct.codegen;
import java.util.ArrayList;
import java.util.List;

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

 /**
  *
  * <b>General Description:</b>  PepEmployeeManager extends PstManager.  This class
  * manages all PepEmployee objects such as creating, retrieving, saving, and
  * deleting PepEmployee objects.
  *
  * PepEmployeeManager can only instantiated through the getInstance() method.
  *
  *
  * <b>Class Dependencies:</b>
  *   oct.codegen.PepEmployee
  *   oct.pst.PstUserAbstractObject
  *   oct.pst.PstUserManager
  *   oct.pst.PstAbstractObject
  *   oct.pst.PstManager
  *
  *
  * <b>Miscellaneous:</b> None.
  *
  */


public class PepEmployeeManager extends oct.pst.PstUserManager

{
    public static final String NAME = "user";     // The orgname of Object PepEmployee
    public static final String CLASSNAME = "oct.codegen.PepEmployee";     // The className of Object PepEmployee

    private static PepEmployeeManager manager = null;


    /**
     * Construct an empty PepEmployee object
     * @param user A PstUserAbstractObject.
     */
    private PepEmployeeManager(PstUserAbstractObject user)
        throws PmpManagerCreationException
    {
        super(user, NAME, CLASSNAME);
    }

    /**
     * Instantiates a PepEmployeeManager object.
     * @return A PepEmployeeManager.
     */
    public static PepEmployeeManager getInstance()
        throws PmpManagerCreationException, PmpInternalException
    {
        if(manager == null)
        {
            manager = new PepEmployeeManager(PstSystem.getInstance());
        }
        return manager;
    }//End getInstance


    /**
     * Create a new PepEmployee object.
     * @param user The PstUserAbstractObject who is requesting to create a PepEmployee.
     * @param type The type of PepEmployee to create.<br>
     * @param PepEmployeeName The name of the PepEmployee.
     *
     * @exception PmpObjectCreationException There was an error creating the PepEmployee.
     * @exception PmpIllegalTypeException The specified compnaytype is invalid.
     * @return The data object that was created.  An explicit cast is required to convert to a PepEmployee object.
     */
    public PstAbstractObject create(PstUserAbstractObject user, String PepEmployeeName)
        throws PmpIllegalTypeException, PmpObjectCreationException
    {
        return create(user.getSession(), PepEmployeeName);
    }//End create

    /**
     * Create a new PepEmployee object.
     * @param session An OmsSession.
     * @param type The type of PepEmployee to create.<br>
     * @param PepEmployeeName The name of the PepEmployee.
     * @exception PmpObjectCreationException There was an error creating the PepEmployee.
     * @exception PmpIllegalTypeException The specified PepEmployee type is invalid.
     * @return The data object that was created.  An explicit cast is required to convert to a PepEmployee object.
     */
    PstAbstractObject create(OmsSession session, String PepEmployeeName)
        throws PmpIllegalTypeException, PmpObjectCreationException
    {
        PepEmployee PepEmployee = null;
        if(PepEmployeeName == null || PepEmployeeName.length() == 0)
        {
            throw new PmpObjectCreationException("The PepEmployee name cannot be empty.");
        }

        try
        {

            PepEmployee = new PepEmployee(session,m_organization, PepEmployeeName);
            return PepEmployee;
        }
        catch(PmpException pe)
        {
            if(PepEmployee != null)
            {
                try
                {
                    delete(PepEmployee);
                }
                catch(Exception e1)
                {
                }
            }
            throw new PmpObjectCreationException("Error creating PepEmployee object:" + pe.toString());
        }
    }//End create


    /**
     * create creates a new user of the specified type
     * @param user - the user asking to create a user
     * @param type - the type of user to create (i.e. SELLER, BUYER_ADMIN, etc.)  see public static constants
     * @return PstUserAbstractObject - the created user
     * @exception PmpObjectCreationException - could not create the user in the databse
     * @exception PmpInternalException - could not create the user
     */
    public PstAbstractObject create(PstUserAbstractObject user, String memberName, String password)
    	throws PmpObjectCreationException, PmpInternalException
    {
		PepEmployee newUser = null;
		try
		{
			newUser = new PepEmployee(user, m_organization, memberName, password);
		}
		catch(PmpException e)
		{
			throw new PmpObjectCreationException("Cannot create new PepEmployee");
		}

		return newUser;
    }



    /**
     * create creates a new object with generated member name
     * @param user - the user asking to create a user
     * @return PstUserAbstractObject - the created user
     * @exception PmpObjectCreationException - could not create the user in the databse
     * @exception PmpInternalException - could not create the user
     */
    public PstAbstractObject create(PstUserAbstractObject user)
    	throws PmpObjectCreationException, PmpInternalException
    {
		PepEmployee newUser = null;
		try
		{
			newUser = new PepEmployee(user, m_organization);
		}
		catch(PmpException e)
		{
			throw new PmpObjectCreationException("Cannot create new PepEmployee");
		}

		return newUser;
    }




    /**
     *
     * Obtain a PepEmployee object from database.
     * @param user  PstUserAbstractObject requesting a PepEmployee object.
     * @param objectId Object id of the PepEmployee object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a PepEmployee object.
     */
    public PstAbstractObject get(PstUserAbstractObject user, int objectId)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(user.getSession(), objectId);
    }//End get

    /**
     *
     * Obtain a PepEmployee object from database.
     * @param session  An OmsSession.
     * @param objectId Object id of the PepEmployee object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a PepEmployee object.
     */
    PstAbstractObject get(OmsSession session, int objectId)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        try
        {
            OmsMember member = new OmsMember(session,objectId);
            if(member.getOrgId() != super.m_organization.getId())
            {
                throw new PmpObjectNotFoundException("Member not in user organization.");
            }

            //Return a PepEmployee object
            return new PepEmployee(member);
        }
        catch(OmsException oe)
        {
            throw new PmpObjectNotFoundException(oe.toString());
        }
    }//End get

    /**
     *
     * Obtain a PepEmployee object from the database.
     * @param user  A PstUserAbstractObject.
     * @param objectName Object name of the PepEmployee object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a PepEmployee object.
     */
    public PstAbstractObject get(PstUserAbstractObject user, String objectName)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(user.getSession(),objectName);
    }//End get

    /**
     *
     * Obtain a PepEmployee object from the database.
     * @param session  An OmsSession.
     * @param objectName Object name of the PepEmployee object.
     * @exception PmpObjectNotFoundException Could not find the specified object.
     * @exception PmpInternalException An internal error occurred.
     * @return The data object with the specified id.  An explicit cast is required to convert to a PepEmployee object.
     */
    PstAbstractObject get(OmsSession session, String objectName)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        try
        {
            OmsMember member = new OmsMember(session, super.m_organization, objectName);
            if(member.getOrgId() != super.m_organization.getId())
            {
                throw new PmpObjectNotFoundException("Member not in user organization.");
            }
            //Return a PepEmployee object
            return new PepEmployee(member);
        }
        catch(OmsException oe)
        {
            throw new PmpObjectNotFoundException(oe.toString());
        }
    }//End get

    /**
     *
     * Obtain an array of PepEmployee objects based on a set of specified object ids.
     * @param user  PstUserAbstractObject requesting the PepEmployee objects.
     * @param objectIds Object ids of all PepEmployee objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a PepEmployee object.
     *   <b>NOTE:</b>  The arrays of PepEmployee will be sorted by object ids,
     *   NOT the order that the ids were specified
     */
    public PstAbstractObject [] get(PstUserAbstractObject user, int [] objectIds)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(user.getSession(), objectIds);
    }//End get

    /**
     *
     * Obtain a Company object based on a set of PepEmployee ids.
     * Obtain an array of PepEmployee objects based on a set of specified object ids.
     * @param session  PstUserAbstractObject requesting the PepEmployee objects.
     * @param objectIds Object ids of all PepEmployee objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a PepEmployee object.
     *   <b>NOTE:</b>  The arrays of PepEmployee will be sorted by object ids,
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
                    return new PepEmployee[0];
            }

            //OmsSession session = user.getSession();
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

            PepEmployee [] result = new PepEmployee[newCount];

            for(int i=0; i<newCount; i++)
            {
                OmsMember member = (OmsMember) memList.get(i);
                //Return a PepEmployee object
                result[i] = new PepEmployee(member);

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
     * Obtain an array of PepEmployee objects based on a set of specified PepEmployee member names.
     * @param session  PstUserAbstractObject requesting the PepEmployee objects.
     * @param objectNames Object names of all PepEmployee objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a PepEmployee object.
     *   <b>NOTE:</b>  The arrays of PepEmployee will be sorted by object ids,
     *   NOT the order that the ids were specified
     */
    public PstAbstractObject [] get(PstUserAbstractObject user, String [] objectNames)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        return get(user.getSession(), objectNames);
    }//End get

    /**
     *
     * Obtain an array of PepEmployee objects based on a set of specified PepEmployee member names.
     * @param session  PstUserAbstractObject requesting the PepEmployee objects.
     * @param objectNames Object names of all PepEmployee objects to retrieve.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An array of data objects with the specified ids.  An explicit cast is required to convert
     *  the data object to a PepEmployee object.
     *   <b>NOTE:</b>  The arrays of PepEmployee will be sorted by object ids,
     *   NOT the order that the ids were specified
     */
    PstAbstractObject [] get(OmsSession session, String [] objectNames)
        throws PmpObjectNotFoundException, PmpInternalException
    {
        int count = objectNames.length;
        if(count <1)
        {
                    return new PepEmployee[0];
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

        PepEmployee [] newResult = new PepEmployee[newCount];
        for(int i=0; i<newCount; i++)
        {
            newResult[i] = (PepEmployee) result.get(i);
        }

        return newResult;

    }//End get

    /**
     *
     * Delete the member from the database.
     * @param dataObject The PepEmployee object to delete permanently.
     * @exception PmpDeleteObjectException Could not delete the specified object.
     */
    public void delete(PstAbstractObject dataObject)
        throws PmpDeleteObjectException
    {
        ((PepEmployee)dataObject).delete();

    }//End delete

    /**
     *
     * Save the member to the database.
     * @param dataObject The PepEmployee object to save.
     * @exception PmpCommitObjectException Could not save the specified object.
     */
    public void commit(PstAbstractObject dataObject)
        throws PmpCommitObjectException
    {
        ((PepEmployee)dataObject).save();

    }//End commit

    /**
     *
     * Refresh the member. Currently, not implemented.
     * @param dataObject The PepEmployee object to refresh.
     */
    public void refresh(PstAbstractObject dataObject)
    {
        ((PepEmployee)dataObject).refresh();

    }//End refresh


    /**
     * Obtain a List of PepEmployee objects based on on the user ID.
     *
     * @param user  PstUserAbstractObject requesting the PepEmployee objects.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An List of PepEmployee objects that is own by this user.
     *
     */
    public List getAllPepEmployee(PstUserAbstractObject user)
        throws PmpObjectNotFoundException, PmpInternalException
    {
		List PepEmployeeList = new ArrayList();
		String expr = "(Owner='" + user.getObjectName() + "')";

		int id[] = this.findId(user.getSession(), expr);

		if (id == null)
			return PepEmployeeList;

		PstAbstractObject objArray[] = this.get(user, id);
		for(int i = 0; i < objArray.length; i++)
		{
			PepEmployeeList.add((PepEmployee)objArray[i]);
		}

        return PepEmployeeList;
    }


    /**
     * Obtain a List of PepEmployee objects that belongs to the PepEmployee.
     *
     * @param projID - int value of a PepEmployee ID.
     * @param user - PstUserAbstractObject requesting the PepEmployee objects.
     * @exception PmpObjectNotFoundException Could not find the specified object(s).
     * @exception PmpInternalException An internal error occurred.
     * @return An List of PepEmployee objects that is own by this user.
     *
     */
    public List getAllPepEmployee(PstUserAbstractObject user, int projID)
        throws PmpObjectNotFoundException, PmpInternalException
    {
		List PepEmployeeList = new ArrayList();
		String expr = "(Parent='" + projID + "')";

		int id[] = this.findId(user.getSession(), expr);

		if (id == null)
			return PepEmployeeList;

		PstAbstractObject objArray[] = this.get(user, id);
		for(int i = 0; i < objArray.length; i++)
		{
			PepEmployeeList.add((PepEmployee)objArray[i]);
		}

        return PepEmployeeList;
    }


    /**
     * Add a dynamic attribute to the purchase order object definition
     * @param <b> user </b> user object
     * @param <b> attObject </b> object contains information of the attribute to be added
     * @return a list of PstAttributeObject objects
     * @exception PmpAddAttributeException could not add attribute.
     * @exception PmpInternalException internal errors
     */
    public void addAttribute(PstUserAbstractObject user, String attributeName, boolean required)
        throws PmpInternalException
    {
        super.addAttribute(user, attributeName, required);
    }

    /**
     * Remove an attribute
     * @param <b> user </b> user object
     * @param <b> attname </b> name of the attribute to be deleted
     * @exception PmpAttributeNotFoundException attribute cannot be found
     * @exception PmpInternalException internal error.
     */
    public void removeAttribute(PstUserAbstractObject user, String attName)
    	throws PmpInternalException, PmpAttributeNotFoundException, PmpInvalidAttributeException
    {
        super.removeAttribute(user,attName);
    }

    /**
     * Return a PstAttributeObject that contains information of the given attribute name,
     * including system and dynmaic attribute.
     * @param <b> user </b> user object
     * @param <b> attName </b> name of the attribure to be returned
     * @return a PstAttributeObject object
     * @exception PmpAttributeNotFoundException attribute cannot be found
     * @exception PmpInternalException internal error.

    public PstAttributeObject getAttribute(PstUserAbstractObject user, String attName)
        throws PmpAttributeNotFoundException, PmpInternalException
    {
        PstAttributeObject attribData = super.getAttribute(user,attName);
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


}//End class PepEmployeeManager
