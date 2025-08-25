// Enhanced search_message.dart with proper history management

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/theme_provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';

/// Search delegate for searching through forum messages
class MessageSearchDelegate extends SearchDelegate<String> {
  final ThemeProvider themeProvider;
  final DatabaseReference messagesRef;
  final Function(String messageId) onMessageFound;
  final MessageSearchLogic _searchLogic;
  Timer? _debounceTimer;
  
  // Add a notifier to trigger rebuilds
  final ValueNotifier<int> _refreshNotifier = ValueNotifier<int>(0);

  MessageSearchDelegate({
    required this.themeProvider,
    required this.messagesRef,
    required this.onMessageFound,
  }) : _searchLogic = MessageSearchLogic(messagesRef);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
        iconTheme: IconThemeData(
          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
        ),
        toolbarTextStyle: TextStyle(
          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
        ),
        titleTextStyle: TextStyle(
          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      scaffoldBackgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
    );
  }

  @override
  void close(BuildContext context, String result) {
    _debounceTimer?.cancel();
    _refreshNotifier.dispose();
    if (result.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onMessageFound(result);
      });
    }
    super.close(context, result);
  }

  @override
  String get searchFieldLabel => 'Search messages or usernames...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(
            Icons.clear,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
          ),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.arrow_back,
        color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
      ),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return _buildEmptyState('Enter text to search messages and usernames');
    }

    return FutureBuilder<List<SearchResult>>(
      future: _searchLogic.searchMessages(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFF2196F3),
                ),
                SizedBox(height: 16),
                Text(
                  'Searching for "$query"...',
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorState('Error searching messages: ${snapshot.error}');
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return _buildEmptyState('No messages found for "$query"');
        }

        return ListView.builder(
          itemCount: results.length,
          padding: EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final result = results[index];
            return _buildResultItem(context, result);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return ValueListenableBuilder<int>(
        valueListenable: _refreshNotifier,
        builder: (context, value, child) {
          return FutureBuilder<List<String>>(
            key: ValueKey(value), // Force rebuild when value changes
            future: _searchLogic.getRecentSearchTerms(),
            builder: (context, snapshot) {
              final recentTerms = snapshot.data ?? [];

              if (recentTerms.isEmpty) {
                return _buildEmptyState('Start typing to search messages...');
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Searches',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                        if (recentTerms.isNotEmpty)
                          TextButton(
                            onPressed: () async {
                              await _searchLogic.clearRecentSearches();
                              _refreshNotifier.value++; // Trigger rebuild
                            },
                            child: Text(
                              'Clear All',
                              style: TextStyle(
                                color: Color(0xFF2196F3),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: recentTerms.length,
                      itemBuilder: (context, index) {
                        final term = recentTerms[index];
                        return ListTile(
                          leading: Icon(
                            Icons.history,
                            color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                          title: Text(
                            term,
                            style: TextStyle(
                              color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          onTap: () {
                            query = term;
                            showResults(context);
                          },
                          trailing: IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                            onPressed: () async {
                              await _searchLogic.removeRecentSearchTerm(term);
                              _refreshNotifier.value++; // Trigger rebuild
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    // Real-time search with debounce
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      // Trigger rebuild for real-time results
    });

    return FutureBuilder<List<SearchResult>>(
      future: _searchLogic.searchMessages(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: Color(0xFF2196F3),
                strokeWidth: 2,
              ),
            ),
          );
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return _buildEmptyState('No suggestions found for "$query"');
        }

        return ListView.builder(
          itemCount: results.length,
          padding: EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final result = results[index];
            return _buildSuggestionItem(context, result);
          },
        );
      },
    );
  }

  Widget _buildSuggestionItem(BuildContext context, SearchResult result) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _getAvatarColor(result.senderName),
            shape: BoxShape.circle,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender name
            Text(
              result.senderName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            SizedBox(height: 2),
            // Message preview with highlighting
            RichText(
              text: TextSpan(
                children: _highlightMatch(result.message, query),
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            _formatTimestamp(result.timestamp),
            style: TextStyle(
              fontSize: 11,
              color: themeProvider.isDarkMode ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ),
        onTap: () async {
          // Only save to history when user actually selects a message
          if (query.trim().length >= 2) { // Only save if search term is meaningful
            await _searchLogic.saveRecentSearchTerm(query.trim());
          }
          close(context, result.messageId);
          onMessageFound(result.messageId);
        },
      ),
    );
  }

  Widget _buildResultItem(BuildContext context, SearchResult result) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // Only save to history when user actually selects a message
          if (query.trim().length >= 2) { // Only save if search term is meaningful
            await _searchLogic.saveRecentSearchTerm(query.trim());
          }
          close(context, result.messageId);
          onMessageFound(result.messageId);
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with sender info and timestamp
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getAvatarColor(result.senderName),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.senderName,
                      style: TextStyle(
                        color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    _formatTimestamp(result.timestamp),
                    style: TextStyle(
                      color: themeProvider.isDarkMode ? Colors.grey[500] : Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8),
              
              // Message content with highlighting
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode 
                    ? Colors.grey[700]?.withOpacity(0.5) 
                    : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: themeProvider.isDarkMode 
                      ? Colors.grey[600]! 
                      : Colors.grey[300]!,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message type indicator
                    if (result.messageType != 'text') ...[
                      Row(
                        children: [
                          Icon(
                            result.messageType == 'image' 
                              ? Icons.image 
                              : result.messageType == 'video' 
                                ? Icons.video_library
                                : Icons.poll,
                            size: 14,
                            color: Color(0xFF2196F3),
                          ),
                          SizedBox(width: 4),
                          Text(
                            result.messageType.toUpperCase(),
                            style: TextStyle(
                              color: Color(0xFF2196F3),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                    ],
                    
                    // Message text with highlighting
                    RichText(
                      text: TextSpan(
                        children: _highlightMatch(result.message, query),
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                          fontSize: 15,
                          height: 1.3,
                        ),
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 8),
              
              // Action hint
              Row(
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 12,
                    color: Color(0xFF87CEEB),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Tap to jump to message',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF87CEEB),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Color(0xFF2196F3), Color(0xFF4CAF50), Color(0xFFFF9800),
      Color(0xFF9C27B0), Color(0xFFE91E63), Color(0xFF00BCD4),
      Color(0xFF795548), Color(0xFF607D8B), Color(0xFFFF5722),
      Color(0xFF3F51B5), Color(0xFF8BC34A), Color(0xFFFFC107),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          SizedBox(height: 16),
          Text(
            error,
            style: TextStyle(
              fontSize: 16,
              color: Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<TextSpan> _highlightMatch(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }

    final queryLower = query.toLowerCase();
    final textLower = text.toLowerCase();
    final matches = <TextSpan>[];

    int start = 0;
    int index = textLower.indexOf(queryLower, start);

    while (index != -1) {
      // Add text before match
      if (index > start) {
        matches.add(TextSpan(text: text.substring(start, index)));
      }

      // Add highlighted match
      matches.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: Color(0xFF2196F3).withOpacity(0.3),
          fontWeight: FontWeight.bold,
          color: Color(0xFF1565C0),
        ),
      ));

      start = index + query.length;
      index = textLower.indexOf(queryLower, start);
    }

    // Add remaining text
    if (start < text.length) {
      matches.add(TextSpan(text: text.substring(start)));
    }

    return matches;
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return DateFormat('MMM dd, yyyy').format(date);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Data model for search results
class SearchResult {
  final String messageId;
  final String message;
  final String senderName;
  final String senderId;
  final int timestamp;
  final String messageType;
  final String? mediaUrl;
  final bool isEdited;

  SearchResult({
    required this.messageId,
    required this.message,
    required this.senderName,
    required this.senderId,
    required this.timestamp,
    required this.messageType,
    this.mediaUrl,
    this.isEdited = false,
  });

  factory SearchResult.fromMap(String messageId, Map<String, dynamic> data) {
    return SearchResult(
      messageId: messageId,
      message: data['message']?.toString() ?? '',
      senderName: data['senderName']?.toString() ?? 'Unknown User',
      senderId: data['senderId']?.toString() ?? '',
      timestamp: data['createdAt'] ?? data['timestamp'] ?? 0,
      messageType: data['messageType']?.toString() ?? 'text',
      mediaUrl: data['mediaUrl']?.toString(),
      isEdited: data['isEdited'] ?? false,
    );
  }
}

/// Logic class for handling search operations
class MessageSearchLogic {
  final DatabaseReference messagesRef;
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 10;

  MessageSearchLogic(this.messagesRef);

  /// Search messages by text content and username with improved performance
  /// This method does NOT save to history - only for searching
  Future<List<SearchResult>> searchMessages(String query) async {
    try {
      final snapshot = await messagesRef.once();

      if (!snapshot.snapshot.exists) {
        return [];
      }

      final data = snapshot.snapshot.value;
      if (data == null) {
        return [];
      }

      Map<String, dynamic> messagesData;

      if (data is Map<Object?, Object?>) {
        messagesData = Map<String, dynamic>.from(data);
      } else if (data is Map<String, dynamic>) {
        messagesData = data;
      } else {
        return [];
      }

      final results = <SearchResult>[];
      final queryLower = query.toLowerCase().trim();

      messagesData.forEach((messageId, messageData) {
        try {
          if (messageData != null && messageData is Map) {
            Map<String, dynamic> msgMap;

            if (messageData is Map<Object?, Object?>) {
              msgMap = Map<String, dynamic>.from(messageData);
            } else if (messageData is Map<String, dynamic>) {
              msgMap = messageData;
            } else {
              return;
            }

            final searchResult = SearchResult.fromMap(messageId, msgMap);

            // Enhanced search logic
            final messageContent = searchResult.message.toLowerCase();
            final senderName = searchResult.senderName.toLowerCase();

            bool matchFound = messageContent.contains(queryLower) || 
                            senderName.contains(queryLower);

            // Also search in message type descriptions for media
            if (!matchFound && searchResult.messageType != 'text') {
              final typeDescription = '${searchResult.messageType} message'.toLowerCase();
              matchFound = typeDescription.contains(queryLower);
            }

            if (matchFound) {
              results.add(searchResult);
            }
          }
        } catch (e) {
          print('Error processing message $messageId: $e');
        }
      });

      // Sort results by relevance and timestamp
      results.sort((a, b) {
        // Prioritize exact username matches
        final aExactUser = a.senderName.toLowerCase() == queryLower;
        final bExactUser = b.senderName.toLowerCase() == queryLower;
        
        if (aExactUser && !bExactUser) return -1;
        if (!aExactUser && bExactUser) return 1;
        
        // Then by message content relevance (starts with query)
        final aStartsWith = a.message.toLowerCase().startsWith(queryLower);
        final bStartsWith = b.message.toLowerCase().startsWith(queryLower);
        
        if (aStartsWith && !bStartsWith) return -1;
        if (!aStartsWith && bStartsWith) return 1;
        
        // Finally by timestamp (newest first)
        return b.timestamp.compareTo(a.timestamp);
      });

      // Limit results for performance
      return results.take(50).toList();
    } catch (e) {
      print('Error searching messages: $e');
      return [];
    }
  }

  /// Get search suggestions based on partial query (now used for real-time results)
  Future<List<String>> getSuggestions(String query) async {
    try {
      final snapshot = await messagesRef.once();

      if (!snapshot.snapshot.exists) {
        return [];
      }

      final data = snapshot.snapshot.value;
      if (data == null) {
        return [];
      }

      Map<String, dynamic> messagesData;

      if (data is Map<Object?, Object?>) {
        messagesData = Map<String, dynamic>.from(data);
      } else if (data is Map<String, dynamic>) {
        messagesData = data;
      } else {
        return [];
      }

      final suggestions = <String>{};
      final queryLower = query.toLowerCase().trim();

      messagesData.forEach((messageId, messageData) {
        try {
          if (messageData != null && messageData is Map) {
            Map<String, dynamic> msgMap;

            if (messageData is Map<Object?, Object?>) {
              msgMap = Map<String, dynamic>.from(messageData);
            } else if (messageData is Map<String, dynamic>) {
              msgMap = messageData;
            } else {
              return;
            }

            final senderName = (msgMap['senderName'] ?? '').toString();
            final message = (msgMap['message'] ?? '').toString();

            // Add username suggestions
            if (senderName.toLowerCase().startsWith(queryLower) && senderName.isNotEmpty) {
              suggestions.add(senderName);
            }

            // Add word suggestions from messages
            if (message.isNotEmpty) {
              final words = message.split(RegExp(r'\s+'));
              for (final word in words) {
                final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
                if (cleanWord.toLowerCase().startsWith(queryLower) && cleanWord.length > 2) {
                  suggestions.add(cleanWord);
                }
              }
            }
          }
        } catch (e) {
          print('Error processing suggestion for message $messageId: $e');
        }
      });

      final suggestionList = suggestions.toList();
      suggestionList.sort();
      return suggestionList.take(10).toList();
    } catch (e) {
      print('Error getting suggestions: $e');
      return [];
    }
  }

  /// Public method to save recent search term - only called when user selects a result
  Future<void> saveRecentSearchTerm(String term) async {
    try {
      final cleanTerm = term.trim();
      if (cleanTerm.isEmpty || cleanTerm.length < 2) return;

      final prefs = await SharedPreferences.getInstance();
      List<String> recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];

      // Remove if already exists to avoid duplicates
      recentSearches.remove(cleanTerm);
      // Add to the beginning
      recentSearches.insert(0, cleanTerm);

      // Keep only the most recent searches
      if (recentSearches.length > _maxRecentSearches) {
        recentSearches = recentSearches.take(_maxRecentSearches).toList();
      }

      await prefs.setStringList(_recentSearchesKey, recentSearches);
    } catch (e) {
      print('Error saving recent search term: $e');
    }
  }

  /// Get recent search terms
  Future<List<String>> getRecentSearchTerms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_recentSearchesKey) ?? [];
    } catch (e) {
      print('Error getting recent search terms: $e');
      return [];
    }
  }

  /// Remove a recent search term
  Future<void> removeRecentSearchTerm(String term) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];
      recentSearches.remove(term);
      await prefs.setStringList(_recentSearchesKey, recentSearches);
    } catch (e) {
      print('Error removing recent search term: $e');
    }
  }

  /// Clear all recent searches
  Future<void> clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesKey);
    } catch (e) {
      print('Error clearing recent searches: $e');
    }
  }
}