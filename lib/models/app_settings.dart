class AppSettings {
  String githubToken;
  String repoOwner;
  String repoName;
  String geminiApiKey;
  String ntfyTopic;

  AppSettings({
    this.githubToken = '',
    this.repoOwner = '',
    this.repoName = '',
    this.geminiApiKey = '',
    this.ntfyTopic = 'ares_builder_notification_ibrahim',
  });
}
