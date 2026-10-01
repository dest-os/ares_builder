class GithubConfig {
  final String username;
  final String token;
  final String repository;
  final String branch;

  const GithubConfig({
    required this.username,
    required this.token,
    this.repository = 'Ares-Builder',
    this.branch = 'main',
  });

  bool get isValid =>
      username.trim().isNotEmpty &&
      token.trim().isNotEmpty &&
      repository.trim().isNotEmpty &&
      branch.trim().isNotEmpty;

  Map<String, dynamic> toJson() => {
        'username': username,
        'token': token,
        'repository': repository,
        'branch': branch,
      };

  factory GithubConfig.fromJson(Map<String, dynamic> json) => GithubConfig(
        username: (json['username'] ?? '').toString(),
        token: (json['token'] ?? '').toString(),
        repository: (json['repository'] ?? 'Ares-Builder').toString(),
        branch: (json['branch'] ?? 'main').toString(),
      );
}
