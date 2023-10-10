/**
* @author Veera Maddukuri
* @date 2021-11
* @description Constant class to keep OCUS API Service constants
*/
public with sharing class CDdOCUSAPIConstants {

    public static final String OCUS_MEDIAFILES_QUERY = 'media.files';
    public static final String OCUS_ARCHIVE_MEDIAFILES_QUERY = 'archives';
    public static final String OCUS_BLOCKER_QUERY = 'events.blocker';
    public static final String OCUS_ADDRESS_QUERY = 'address';
    public static final String OCUS_CATEGORY = 'OCUSCredentials';
    public static final String OCUS_AUTH_HEADER = 'Bearer';
    public static final String OCUS_BLOCKER_EVENT = 'mission.blocker.set';
    public static final String OCUS_UPDATE_EVENT = 'mission.status.updated';
    public static final String OCUS_ADDRESS_EVENT = 'mission.address.approximate';
    public static final String OCUS_MISSION_ARCHIVED_EVENT = 'mission.archived';
    public static final String ADDRESS_VERIFICATION_STATUS = 'ADDRESS_VERIFICATION';
    public static final String BLOCKED_STATUS = 'BLOCKED';
    public static final String OCUS = 'OCUS';

    public static List<String> OCUS_COUNTRY_CODES = new List<String>{'JP','DE'};
    public static List<String> OCUS_SUBMARKET_ENABLED_COUNTRY_CODES = new List<String> {'CA','US'};
    public static List<String> OCUS_CAVIAR_ENABLED_COUNTRY_CODES = new List<String> {'US'};

    public static final List<Integer> STATUS_CODES_SUCCESS = new List<Integer>{
        200,
        201,
        204
    };

    public static final List<Integer> STATUS_CODES_SERVER_ERROR = new List<Integer>{
        500,
        501
    };

    public static Map<String,String> COUNTRYCODE_TIME_ZONE = new Map<String,String>{
        'DE' => 'Europe/Berlin',
        'JP' => 'Asia/Tokyo'
    };

    public static final Map<String, String> OCUS_CASE_STATUS_MAPPING = new Map<String, String> {
        'ARCHIVED' => 'Closed',
        'ASSIGNED' => 'Open',
        'APPOINTMENT_CONFIRMED' => 'Assigned',
        'CANCELED' => 'Closed',
        'COMPLETED' => 'Closed',
        'DELIVERED' => 'Photoshoot Complete',
        'IN_POST-PRODUCTION' => 'Photoshoot Complete',
        'ORDERED' => 'Open',
        'UNASSIGNED' => 'Open',
        'WAITING_MEDIA_UPLOAD' => 'Assigned',
        'BLOCKED' => 'Blocked',
        'ADDRESS_VERIFICATION' => 'Blocked'
    };

    public static final Set<String> queueDeveloperNames = new Set<String>{
        'Photo_Escalations',
        'Photoshoot_cases_Japan_OCUS',
        'Photoshoot_cases_Germany_OCUS',
        'Photoshoot_cases_Canada_OCUS',
        'Photoshoot_cases_PR_OCUS',
        'Photoshoot_cases_US_OCUS',
        'Photoshoot_cases_caviar_US_OCUS',
        'Photoshoot_cases_OCUS_errors_Japan',
        'Photoshoot_cases_OCUS_errors_Germany',
        'Photoshoot_cases_OCUS_errors_Canada',
        'Photoshoot_cases_OCUS_errors_PR',
        'Photoshoot_cases_OCUS_errors_US',
        'Photoshoot_cases_caviar_OCUS_errors_US'
    };

}