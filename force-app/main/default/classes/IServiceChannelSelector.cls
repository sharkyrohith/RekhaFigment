public interface IServiceChannelSelector extends fflib_ISObjectSelector {
    ServiceChannel selectByRelatedEntity(String relatedEntity);
}