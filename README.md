# UDActiveDirectoryPortal
The Active Directory Portal Built with Universal DashBoard

![Image of UD](https://github.com/jagannath79/UDActiveDirectoryPortal/blob/main/LoginPage.JPG)

Username and Password is currently static and is not integrated with AD

* Username: Admin
* Password: Test

The Active Directory Portal is built with Universal Dashboard. The Active Directory Portal has 6 main sections/tabs:

1. Home
2. AD Users
3. AD Groups
4. AD OnBoarding
5. AD Group Creation
6. Reports

Note: AD OnBoarding as per the use case that I have followed is little different where it connects to the SQL Database to fetch the account to be copied from.

The Active Directory Portal has also the connectivity to MS SQL Server database to fetch the records.

Home Tab: This currently does not have any thing in it plan is to add various charts and dashboards as part of Home Tab.

![Image of UDHome](https://github.com/jagannath79/UDActiveDirectoryPortal/blob/main/Home.jpg)

**AD Users Tab:** This has the features to search the AD Account using:
* SamAccountName / NetworkID
* FirstName
* LastName
* EmployeeID

![Image of UDADUsers](https://github.com/jagannath79/UDActiveDirectoryPortal/blob/main/ADUsers.JPG)

When you search an AD Account with SamAccountName/NetworkID it will display the below details of the users:

* User Details
* Group Membership Details
* extensionAttribute Details (Here in my case I have taken (extensionAttribute2, extensionAttribute5 and msDS-cloudExtensionAttribute2
* Other Applicaion Accesses (Here it connects to the in-house SQL DB and quries and returns info)
* Direct Reports of that user

![Image of UDADUsers1](https://github.com/jagannath79/UDActiveDirectoryPortal/blob/main/ADUsers1.JPG)
![Image of UDADUsers2](https://github.com/jagannath79/UDActiveDirectoryPortal/blob/main/ADUsers2.JPG)
![Image of UDADUsers3](https://github.com/jagannath79/UDActiveDirectoryPortal/blob/main/ADUsers3.JPG)
![Image of UDADUsers4](https://github.com/jagannath79/UDActiveDirectoryPortal/blob/main/ADUsers4.JPG)

AD Groups Tab: This tab gives a feature to display the Group Membership of a Group.

![Image of UDADGroups](https://github.com/jagannath79/UDActiveDirectoryPortal/blob/main/ADGroups.JPG)

**Note: This feature requires a PS Module ADEssentials**
**Download Link: [ADEssentials](https://www.powershellgallery.com/packages/ADEssentials/0.0.102)** 

AD OnBoarding Tab: This form creates a new user account depending on the values passed in the form. Note: This feature will not work with lot of the people as I have coded this for a special use case where it connects to the SQL Database to fetch the template account that needs to be copied.

AD Group Creation Tab: This form creates a new Security Group.

Reports Tab: This tab provides users with different kind of AD Reports, to start with I have added below reports which might not be apt for many people but you can always add you own reports:
-> Account In DisabledTermsOU
-> No Employee ID tagged for Associate
-> No Employee ID tagged for Non Associate
-> Expired Account Last 7 Days
