Feature: Validate checksums for WordPress plugins

  Scenario: Verify plugin checksums
    Given a WP install

    When I run `wp plugin install duplicate-post --version=3.2.1`
    Then STDOUT should not be empty
    And STDERR should be empty

    When I run `wp checksum plugin duplicate-post`
    Then STDOUT should be:
      """
      Success: Verified 1 of 1 plugins.
      """

  Scenario: Modified plugin doesn't verify
    Given a WP install

    When I run `wp plugin install duplicate-post --version=3.2.1`
    Then STDOUT should not be empty
    And STDERR should be empty

    Given "Duplicate Post" replaced with "Different Name" in the wp-content/plugins/duplicate-post/duplicate-post.php file

    When I try `wp checksum plugin duplicate-post --format=json`
    Then STDOUT should contain:
      """
      "plugin_name":"duplicate-post","file":"duplicate-post.php","message":"Checksum does not match"
      """
    And STDERR should be:
      """
      Error: No plugins verified (1 failed).
      """

    When I run `rm wp-content/plugins/duplicate-post/duplicate-post.css`
    Then STDERR should be empty

    When I try `wp checksum plugin duplicate-post --format=json`
    Then STDOUT should contain:
      """
      "plugin_name":"duplicate-post","file":"duplicate-post.css","message":"File is missing"
      """
    And STDERR should be:
      """
      Error: No plugins verified (1 failed).
      """

    When I run `touch wp-content/plugins/duplicate-post/additional-file.php`
    Then STDERR should be empty

    When I try `wp checksum plugin duplicate-post --format=json`
    Then STDOUT should contain:
      """
      "plugin_name":"duplicate-post","file":"additional-file.php","message":"File was added"
      """
    And STDERR should be:
      """
      Error: No plugins verified (1 failed).
      """

  Scenario: Soft changes are only reported in strict mode
    Given a WP install

    When I run `wp plugin install duplicate-post --version=3.2.1`
    Then STDOUT should not be empty
    And STDERR should be empty

    Given "Duplicate Post" replaced with "Different Name" in the wp-content/plugins/duplicate-post/readme.txt file

    When I run `wp checksum plugin duplicate-post`
    Then STDOUT should be:
      """
      Success: Verified 1 of 1 plugins.
      """
    And STDERR should be empty

    When I try `wp checksum plugin duplicate-post --strict`
    Then STDOUT should not be empty
    And STDERR should contain:
      """
      Error: No plugins verified (1 failed).
      """

  # WPTouch 4.3.22 contains multiple checksums for some of its files.
  # See https://github.com/wp-cli/checksum-command/issues/24
  Scenario: Multiple checksums for a single file are supported
    Given a WP install

    When I run `wp plugin install wptouch --version=4.3.22`
    Then STDOUT should not be empty
    And STDERR should be empty

    When I run `wp checksum plugin wptouch`
    Then STDOUT should be:
      """
      Success: Verified 1 of 1 plugins.
      """
    And STDERR should be empty

  Scenario: Throws an error if provided with neither plugin names nor the --all flag
    Given a WP install

    When I try `wp checksum plugin`
    Then STDERR should contain:
      """
      You need to specify either one or more plugin slugs to check or use the --all flag to check all plugins.
      """
    And STDOUT should be empty
