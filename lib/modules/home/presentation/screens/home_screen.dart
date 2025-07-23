// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickzip/core/utils/password_generator.dart';
import 'package:quickzip/modules/home/presentation/screens/compressed_screen.dart';
import 'package:quickzip/modules/home/presentation/screens/extracted_screen.dart';
import 'package:quickzip/modules/settings/presentation/screens/settings_screen.dart';
import '../../../../core/services/ads_manager.dart';
import '../../../../core/services/app_router.dart';
import '../../../../core/services/file_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../provider/file_provider.dart';
import '../provider/search_provider.dart';
import '../provider/selection_provider.dart';
import '../provider/extracted_screen_provider.dart';
import '../provider/page_index_provider.dart';
import '../provider/extracted_folder_navigation_provider.dart';
import '../provider/page_controller_provider.dart';
import '../../../../core/utils/show_custom_snackbar.dart';
import '../widgets/breadcrumb_navigation.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  Timer? _adRetryTimer;
  bool hasPermission = false;
  late FileService fileService;
  late PageController _pageController;
  late TextEditingController _searchController;
  DateTime? _lastBackPressTime;
  int _adLoadAttempts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    fileService = ref.read(fileServiceProvider);
    _pageController = ref.read(pageControllerProvider);
    _searchController = TextEditingController();

    // Initial setup
    _initializeApp();

    // Set up periodic refresh
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    // Refresh every 30 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshFiles(),
    );
  }

  Future<void> _checkAndPreloadRewardedAd() async {
    final adsManager = ref.read(adsManagerProvider);

    // If ad is already loaded, don't reload
    if (adsManager.isRewardedAdLoaded) {
      debugPrint('Rewarded ad is already loaded, skipping preload');
      return;
    }

    final compressedFiles = await ref.read(compressedFilesProvider.future);
    final hasTomitoFile = compressedFiles.any(
        (file) => PasswordGenerator.isTomitoFile(file.path.split('/').last));

    if (hasTomitoFile) {
      debugPrint('Found Tomito+ file, preloading rewarded ad');
      await _loadRewardedAdWithRetry();
    }
  }

  Future<void> _loadRewardedAdWithRetry() async {
    final adsManager = ref.read(adsManagerProvider);
    if (adsManager.isRewardedAdLoaded) {
      debugPrint('Rewarded ad already loaded, skipping retry');
      return;
    }

    _adLoadAttempts = 0;
    await _attemptLoadRewardedAd();
  }

  Future<void> _attemptLoadRewardedAd() async {
    if (!mounted) return;

    final adsManager = ref.read(adsManagerProvider);
    if (adsManager.isRewardedAdLoaded) {
      debugPrint('Rewarded ad already loaded during retry attempt');
      return;
    }

    if (_adLoadAttempts >= 3) {
      debugPrint('Maximum ad load attempts reached');
      return;
    }

    try {
      debugPrint(
          'Attempting to load rewarded ad (Attempt ${_adLoadAttempts + 1}/3)');
      await adsManager.loadRewardedAd();

      if (adsManager.isRewardedAdLoaded) {
        debugPrint('Rewarded ad loaded successfully');
        _adLoadAttempts = 0;
        _adRetryTimer?.cancel(); // Cancel any pending retries
      } else {
        _adLoadAttempts++;
        if (_adLoadAttempts < 3) {
          _adRetryTimer?.cancel();
          _adRetryTimer = Timer(
            Duration(seconds: _adLoadAttempts * 2),
            () => _attemptLoadRewardedAd(),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading rewarded ad: $e');
      _adLoadAttempts++;
      if (_adLoadAttempts < 3 && !adsManager.isRewardedAdLoaded) {
        _adRetryTimer?.cancel();
        _adRetryTimer = Timer(
          Duration(seconds: _adLoadAttempts * 2),
          () => _attemptLoadRewardedAd(),
        );
      }
    }
  }

  void _refreshFiles() {
    if (!mounted) return;
    // Refresh both compressed and extracted files
    // ignore: unused_result
    ref.refresh(compressedFilesProvider);
    // ignore: unused_result
    ref.refresh(extractedFilesProvider);
    // Check for Tomito+ files and preload ad if needed
    _checkAndPreloadRewardedAd();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        // App came back to foreground
        _refreshFiles();
        _startPeriodicRefresh();
        break;
      case AppLifecycleState.paused:
        // App went to background
        _refreshTimer?.cancel();
        _adRetryTimer?.cancel();
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _adRetryTimer?.cancel();
    ref.read(adsManagerProvider).disposeBannerAd();
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      final granted = await fileService.requestPermissions();
      if (mounted) {
        setState(() {
          hasPermission = granted;
        });
      }

      if (granted) {
        // Initial file refresh and ad preload
        _refreshFiles();

        // Initialize banner ad
        if (mounted) {
          ref.read(adsManagerProvider).loadBannerAd(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permissions are required'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error initializing app: $e');
    }
  }

  void navigateToExtractedFolder(String folderPath) {
    // Set the page index to Extracted tab
    ref.read(pageIndexProvider.notifier).state = 1;
    // Jump to the Extracted tab immediately
    _pageController.jumpToPage(1);
    // Navigate to the extracted folder using Directory
    ref
        .read(extractedScreenProvider.notifier)
        .navigateToFolder(Directory(folderPath));
  }

  @override
  Widget build(BuildContext context) {
    final selectionState = ref.watch(selectionStateProvider);
    final extractedScreen = ref.watch(extractedScreenProvider);
    final isInExtractedFolder = extractedScreen.currentFolder != null;
    final currentIndex = ref.watch(pageIndexProvider);

    // Make this method available to other parts of the app
    ref.listen<String?>(extractedFolderNavigationProvider, (previous, next) {
      if (next != null) {
        navigateToExtractedFolder(next);
      }
    });

    const pages = [CompressedScreen(), ExtractedScreen()];

    // Show loading indicator while waiting for permissions
    if (!hasPermission) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Platform.isIOS
          ? _buildIOSLayout(currentIndex, pages)
          : _buildAndroidLayout(currentIndex, pages, selectionState,
              isInExtractedFolder, extractedScreen),
    );
  }

  Future<bool> _onWillPop() async {
    final extractedScreen = ref.read(extractedScreenProvider);
    if (extractedScreen.currentFolder != null) {
      // Get the parent folder path
      final currentPath = extractedScreen.currentFolder!.path;
      final parentPath = Directory(currentPath).parent.path;

      // Check if we're going back to root
      if (parentPath == '/storage/emulated/0/QuickZip Extracted Files') {
        ref.read(extractedScreenProvider.notifier).navigateBack();
      } else {
        // Navigate to parent folder
        ref
            .read(extractedScreenProvider.notifier)
            .navigateToFolder(Directory(parentPath));
      }
      ref.read(pageIndexProvider.notifier).state = 1;
      return false;
    }

    // If we're not in a folder, handle normal tab navigation
    final currentIndex = ref.read(pageIndexProvider);
    if (currentIndex != 0) {
      ref.read(pageIndexProvider.notifier).state = 0;
      _pageController.jumpToPage(0);
      return false;
    }

    // If we're on the home tab, show exit confirmation
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      showCustomSnackBar(context, 'Press back again to exit');
      return false;
    }
    return true;
  }

  Widget _buildIOSLayout(int currentIndex, List<Widget> pages) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        middle: _buildTitle(ref),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            AppRoutes.push(const SettingsPage());
            // Navigator.push(
            //   context,
            //   CupertinoPageRoute(builder: (context) => const SettingsPage()),
            // );
          },
          child: const Icon(CupertinoIcons.settings),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            CupertinoSegmentedControl<int>(
              children: const {
                0: Text('Compressed'),
                1: Text('Extracted'),
              },
              onValueChanged: _changeTab,
              groupValue: currentIndex,
            ),
            Expanded(
              child: pages[currentIndex],
            ),
            // adsManager.getBannerAdWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidLayout(
      int currentIndex,
      List<Widget> pages,
      SelectionState selectionState,
      bool isInExtractedFolder,
      ExtractedScreenState extractedScreen) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.darkBackground,
        leading: selectionState.isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  ref.read(selectionStateProvider.notifier).clearSelection();
                },
              )
            : isInExtractedFolder
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      // Get the parent folder path
                      final currentPath = extractedScreen.currentFolder!.path;
                      final parentPath = Directory(currentPath).parent.path;

                      // Check if we're going back to root
                      if (parentPath ==
                          '/storage/emulated/0/QuickZip Extracted Files') {
                        ref
                            .read(extractedScreenProvider.notifier)
                            .navigateBack();
                      } else {
                        // Navigate to parent folder
                        ref
                            .read(extractedScreenProvider.notifier)
                            .navigateToFolder(Directory(parentPath));
                      }
                      ref.read(pageIndexProvider.notifier).state = 1;
                      _pageController.jumpToPage(1);
                    },
                  )
                : null,
        title: selectionState.isSelectionMode
            ? Text('${selectionState.selectedFiles.length} selected')
            : isInExtractedFolder
                ? const Text('Extracted')
                : _buildTitle(ref),
        actions: [
          if (selectionState.isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.primaryWhite),
              onPressed: () => _handleMultipleDelete(context, ref),
            )
          else if (!isInExtractedFolder) ...[
            if (!_isSearching(ref))
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _toggleSearch(ref),
              ),
            if (_isSearching(ref))
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.white),
                onPressed: () {
                  _searchController.clear();
                  _toggleSearch(ref);
                },
              ),
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => AppRoutes.push(const SettingsPage()),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (isInExtractedFolder) ...[
            BreadcrumbNavigation(
              pathSegments: extractedScreen.pathSegments,
              onTap: (index) {
                if (index == 0) {
                  // If tapping on "Extracted", go back to root
                  ref.read(extractedScreenProvider.notifier).navigateBack();
                  ref.read(pageIndexProvider.notifier).state = 1;
                } else if (index < extractedScreen.pathSegments.length - 1) {
                  // Calculate the path up to this segment
                  final pathSegments =
                      extractedScreen.pathSegments.sublist(1, index + 1);
                  final folderPath =
                      '/storage/emulated/0/QuickZip Extracted Files/${pathSegments.join('/')}';

                  // Navigate to the selected folder
                  ref
                      .read(extractedScreenProvider.notifier)
                      .navigateToFolder(Directory(folderPath));
                  ref.read(pageIndexProvider.notifier).state = 1;
                }
              },
            ),
            const Divider(
              height: 1,
              color: Colors.white24,
            ),
          ],
          if (!isInExtractedFolder) _buildTabBar(currentIndex),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: isInExtractedFolder
                  ? const NeverScrollableScrollPhysics()
                  : null,
              onPageChanged: isInExtractedFolder
                  ? null
                  : (index) {
                      ref.read(pageIndexProvider.notifier).state = index;
                      // Clear search when swiping
                      if (index == 0) {
                        ref.read(extractedSearchQueryProvider.notifier).state =
                            '';
                      } else {
                        ref.read(compressedSearchQueryProvider.notifier).state =
                            '';
                      }
                    },
              children: [
                const CompressedScreen(),
                isInExtractedFolder
                    ? const ExtractedScreen()
                    : const ExtractedScreen(),
              ],
            ),
          ),
          // adsManager.getBannerAdWidget(),
        ],
      ),
    );
  }

  bool _isSearching(WidgetRef ref) {
    final currentIndex = ref.watch(pageIndexProvider);
    return currentIndex == 0
        ? ref.watch(compressedSearchQueryProvider).isNotEmpty
        : ref.watch(extractedSearchQueryProvider).isNotEmpty;
  }

  void _toggleSearch(WidgetRef ref) {
    final currentIndex = ref.watch(pageIndexProvider);
    if (_isSearching(ref)) {
      // Clear search
      _searchController.clear();
      if (currentIndex == 0) {
        ref.read(compressedSearchQueryProvider.notifier).state = '';
      } else {
        ref.read(extractedSearchQueryProvider.notifier).state = '';
      }
    } else {
      // Start search
      if (currentIndex == 0) {
        ref.read(compressedSearchQueryProvider.notifier).state = ' ';
      } else {
        ref.read(extractedSearchQueryProvider.notifier).state = ' ';
      }
    }
  }

  Widget _buildTitle(WidgetRef ref) {
    final currentIndex = ref.watch(pageIndexProvider);
    if (_isSearching(ref)) {
      return SizedBox(
        height: 35,
        width: 250,
        child: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Color(0xff111111),
            hintText: 'Search your files...',
            hintStyle: TextStyle(
                color: AppTheme.hintText,
                fontSize: 15,
                fontWeight: FontWeight.w400),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(100)),
              borderSide: BorderSide(color: AppTheme.hintText),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(100)),
              borderSide: BorderSide(color: AppTheme.hintText),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(100)),
              borderSide: BorderSide(color: AppTheme.hintText),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) {
            if (currentIndex == 0) {
              ref.read(compressedSearchQueryProvider.notifier).state = value;
            } else {
              ref.read(extractedSearchQueryProvider.notifier).state = value;
            }
          },
        ),
      );
    }
    return const Text(
      'QuickZip',
      style:
          TextStyle(color: AppTheme.primaryWhite, fontWeight: FontWeight.w700),
    );
  }

  void _changeTab(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    // Clear search when changing tabs
    if (index == 0) {
      ref.read(extractedSearchQueryProvider.notifier).state = '';
    } else {
      ref.read(compressedSearchQueryProvider.notifier).state = '';
    }
  }

  Widget _buildTabBar(int currentIndex) {
    return Column(
      children: [
        Container(
          color: AppTheme.darkBackground,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: currentIndex == 0
                              ? const Color(0xFF1CE783)
                              : const Color(0xFF838383),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Compressed',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: currentIndex == 0
                              ? const Color(0xFF1CE783)
                              : const Color(0xFF838383),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: currentIndex == 1
                              ? const Color(0xFF1CE783)
                              : const Color(0xFF838383),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Extracted',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: currentIndex == 1
                              ? const Color(0xFF1CE783)
                              : const Color(0xFF838383),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 1,
          color: Colors.white24,
        ),
      ],
    );
  }

  void _handleMultipleDelete(BuildContext context, WidgetRef ref) async {
    final selectionState = ref.read(selectionStateProvider);
    //final fileService = ref.read(fileServiceProvider);

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: AppTheme.primaryBlack,
        title: const Text(
          'Delete Files',
          style: TextStyle(
              color: AppTheme.primaryWhite, fontWeight: FontWeight.w500),
        ),
        content: Text(
          'Are you sure you want to delete ${selectionState.selectedFiles.length} items?',
          style: const TextStyle(
              color: AppTheme.primaryWhite, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                  color: AppTheme.lightWhite, fontWeight: FontWeight.w400),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                  color: AppTheme.primaryGreen, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true && context.mounted) {
      try {
        for (final path in selectionState.selectedFiles) {
          final fileEntity = File(path);
          final dirEntity = Directory(path);

          if (await dirEntity.exists()) {
            await dirEntity.delete(recursive: true);
          } else if (await fileEntity.exists()) {
            await fileEntity.delete();
          }
        }

        if (context.mounted) {
          showCustomSnackBar(context, 'Items deleted successfully');

          ref.read(selectionStateProvider.notifier).clearSelection();
          // ignore: unused_result
          ref.refresh(compressedFilesProvider);
          // ignore: unused_result
          ref.refresh(extractedFilesProvider);
        }
      } catch (e) {
        if (context.mounted) {
          showCustomSnackBar(context, 'Error deleting items: $e');
        }
      }
    }
  }
}
