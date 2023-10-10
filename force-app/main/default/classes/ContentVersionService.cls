public inherited sharing class ContentVersionService {
    public static void createCSVContentFileSalesforce(String fileName, String blobVal) {
        service().createCSVContentFileSalesforce(fileName,blobVal);
    }

    private static IContentVersionService service() {
        return (IContentVersionService) Application.Service.newInstance(IContentVersionService.class);
    }
}