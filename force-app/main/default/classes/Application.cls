/**
 * @description Provides access to preconfigured instances of Enterprise Pattern factories
 * Service, Unit Of Work, Selector and Domain.
 * @author Scott McClung
 * @date 2022/08/16
 */
public class Application {
    // Configure and create the UnitOfWorkFactory for this Application
    public static final ApplicationUnitOfWorkFactory UnitOfWork = new ApplicationUnitOfWorkFactory(
        new List<SObjectType>{
            Lead.SObjectType,
            Account.SObjectType,
            Contact.SObjectType,
            Opportunity.SObjectType,
            Case.SObjectType,
            User.SObjectType,
            Document.SObjectType,
            MXP_BoB_Update_Request__c.SObjectType,
            AccountTeamMember.SObjectType,
            Milestone__c.SObjectType,
            ContentVersion.SObjectType,
            API_Log__c.SObjectType,
            API_Logger__e.SObjectType,
            FeedItem.SObjectType,
            Integration_Request__x.SObjectType,
            PendingServiceRouting.SObjectType,
            SkillRequirement.SObjectType,
            Session_Time__c.SObjectType
        }
    );

    // Configure and create the ServiceFactory for this Application
    public static final ApplicationServiceFactory Service = new ApplicationServiceFactory(
        new Map<Type, Type>{
            IProfileImageService.class => ProfileImageServiceImpl.class,
            IMxpBobUpdateRequestService.class => MxpBoBUpdateRequestServiceImpl.class,
            IContentVersionService.class => ContentVersionServiceImpl.class,
            IApiLoggerService.class => ApiLoggerServiceImpl.class,
            IRealTimeAlertService.class => RealTimeAlertServiceImpl.class,
            ICloseOpenCasesRequestService.class => CloseOpenCasesRequestServiceImpl.class,
            IEmailGeneratorService.class => EmailGeneratorServiceImpl.class,
            IAccountNotificationService.class => AccountNotificationServiceImpl.class,
            IPendingServiceRoutingService.class => PendingServiceRequestServiceImpl.class,
            IAttributeBasedRoutingService.class => AttributeBasedRoutingServiceImpl.class,
            ISessionTimeService.class => SessionTimeServiceImpl.class
        }
    );

    // Configure and create the SelectorFactory for this Application
    public static final ApplicationSelectorFactory Selector = new ApplicationSelectorFactory(
        new Map<SObjectType, Type>{
            Lead.SObjectType => LeadsSelector.class,
            Account.SObjectType => AccountsSelector.class,
            Contact.SObjectType => ContactsSelector.class,
            Opportunity.SObjectType => OpportunitiesSelector.class,
            Case.SObjectType => CasesSelector.class,
            User.SObjectType => UsersSelector.class,
            Folder.SObjectType => FoldersSelector.class,
            MXP_BoB_Update_Request__c.SObjectType => MXPBoBUpdateRequestSelector.class,
            AccountTeamMember.SObjectType => AccountTeamMembersSelector.class,
            ProcessInstance.SObjectType => ProcessInstanceSelector.class,
            Order.SObjectType => OrdersSelector.class,
            OrderItem.SObjectType => OrderItemsSelector.class,
            Product2.SObjectType => ProductsSelector.class,
            Api_Logger_Gate__c.SObjectType => ApiLoggerGateSelector.class,
            Milestone__c.SObjectType => MilestonesSelector.class,
            CaseHistory.SObjectType => CaseHistoriesSelector.class,
            FeedItem.SObjectType => FeedItemSelector.class,
            Integration_Request__x.SObjectType =>IntegrationRequestsSelector.class,
            Bat_To_Milestone_Status_Mapping__mdt.SObjectType => BatToMilestoneStatusMappingSelector.class,
            Account_Notification__c.SObjectType => AccountNotificationSelector.class,
            ServiceChannel.SObjectType => ServiceChannelsSelector.class,
            Attribute_Based_Routing_Setting__c.SObjectType => AttributeBasedRoutingSettingsSelector.class,
            Routing_Attribute_Defination__mdt.SObjectType => RoutingAttributeDefinationsSelector.class,
            Skill.SObjectType => SkillsSelector.class,
            Session_Time__c.SObjectType => SessionTimeSelector.class
        }
    );

    // Configure and create the DomainFactory for this Application
    public static final ApplicationDomainFactory Domain = new ApplicationDomainFactory(
        Application.Selector,
        new Map<Object, Type>{
            Lead.SObjectType => Leads.Constructor.class,
            Account.SObjectType => Accounts.Constructor.class,
            Contact.SObjectType => Contacts.Constructor.class,
            Opportunity.SObjectType => Opportunities.Constructor.class,
            Case.SObjectType => Cases.Constructor.class,
            IRecordTypeInfos.class => RecordTypeInfos.Constructor.class,
            MXP_BoB_Update_Request__c.SObjectType => MxpBoBUpdateRequest.Constructor.class,
            AccountTeamMember.SObjectType => AccountTeamMembers.Constructor.class,
            API_Log__c.SObjectType => ApiLogs.Constructor.class,
            Integration_Request__x.SObjectType => IntegrationRequestsSelector.Constructor.class,
            Account_Notification__c.SObjectType => AccountNotifications.Constructor.class,
            Session_Time__c.SObjectType => SessionTimes.Constructor.class
        }
    );
}