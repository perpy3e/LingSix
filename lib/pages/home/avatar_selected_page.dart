import 'package:flutter/material.dart';
import 'package:lingsix/app/router.dart';
import 'package:lingsix/app/theme.dart';
import 'package:lingsix/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class AvatarSelectedPage extends StatefulWidget {
	const AvatarSelectedPage({super.key});

	@override
	State<AvatarSelectedPage> createState() => _AvatarSelectedPageState();
}

class _AvatarSelectedPageState extends State<AvatarSelectedPage> {
	late String _selectedCharacter;

	@override
	void initState() {
		super.initState();
		final provider = context.read<ThemeProvider>();
		_selectedCharacter = provider.selectedCharacter;
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: Consumer<ThemeProvider>(
				builder: (context, themeProvider, _) {
					return Container(
						decoration: BoxDecoration(
							image: DecorationImage(
								image: AssetImage(themeProvider.getWallpaperPath('home')),
								fit: BoxFit.cover,
								onError: (error, stackTrace) {},
							),
						),
						child: SafeArea(
							child: Column(
								children: [
									const SizedBox(height: 32),
									Padding(
										padding: const EdgeInsets.symmetric(horizontal: 16),
										child: Row(
											mainAxisAlignment: MainAxisAlignment.spaceBetween,
											children: themeProvider.availableCharacters
    .map<Widget>(
      (String character) => Expanded(
															child: Padding(
																padding: const EdgeInsets.symmetric(
																	horizontal: 6,
																),
																child: _CharacterHeadCard(
																	headPath: themeProvider.getCharacterHeadPath(
																		character,
																	),
																	fallbackHeadPath: themeProvider
																			.getDefaultCharacterHeadPath(character),
																	isSelected: _selectedCharacter == character,
																	onTap: () {
																		setState(() {
																			_selectedCharacter = character;
																		});
																	},
																),
															),
														),
													)
													.toList(),
										),
									),
									const SizedBox(height: 48),
									Padding(
										padding: const EdgeInsets.symmetric(horizontal: 56),
										child: SizedBox(
											width: double.infinity,
											height: 68,
											child: ElevatedButton(
												style: ElevatedButton.styleFrom(
													backgroundColor: const Color.fromARGB(255, 45, 152, 223),
													foregroundColor: Colors.white,
													shape: RoundedRectangleBorder(
														borderRadius: BorderRadius.circular(20),
														side: const BorderSide(
															color: Colors.white,
															width: 2,
														),
													),
													elevation: 0,
												),
												onPressed: () async {
													await themeProvider.setSelectedCharacter(
														_selectedCharacter,
													);

													if (!context.mounted) return;
													Navigator.pushReplacementNamed(
														context,
														AppRouter.homePage,
													);
												},
												child: const Text(
													'เลือกตัวละคร',
													style: TextStyle(
														fontSize: 22,
														fontWeight: FontWeight.w700,
													),
												),
											),
										),
									),
									const Spacer(),
									Expanded(
										flex: 3,
										child: Padding(
											padding: const EdgeInsets.symmetric(horizontal: 24),
											child: Image.asset(
												themeProvider.getCharacterBodyPath(_selectedCharacter),
												fit: BoxFit.contain,
												errorBuilder: (context, error, stackTrace) => Image.asset(
													themeProvider.getDefaultCharacterBodyPath(
														_selectedCharacter,
													),
													fit: BoxFit.contain,
												),
											),
										),
									),
								],
							),
						),
					);
				},
			),
		);
	}
}

class _CharacterHeadCard extends StatelessWidget {
	const _CharacterHeadCard({
		required this.headPath,
		required this.fallbackHeadPath,
		required this.isSelected,
		required this.onTap,
	});

	final String headPath;
	final String fallbackHeadPath;
	final bool isSelected;
	final VoidCallback onTap;

	@override
	Widget build(BuildContext context) {
		return GestureDetector(
			onTap: onTap,
			child: AnimatedContainer(
				duration: const Duration(milliseconds: 180),
				curve: Curves.easeOut,
				padding: const EdgeInsets.all(10),
				decoration: BoxDecoration(
					color: isSelected ? AppColors.yellow300 : Colors.white.withAlpha(230),
					borderRadius: BorderRadius.circular(16),
					border: Border.all(
						color: isSelected ? Colors.white : Colors.black,
						width: isSelected ? 3 : 1,
					),
				),
				child: AspectRatio(
					aspectRatio: 1,
					child: Image.asset(
						headPath,
						fit: BoxFit.contain,
						errorBuilder: (context, error, stackTrace) => Image.asset(
							fallbackHeadPath,
							fit: BoxFit.contain,
						),
					),
				),
			),
		);
	}
}
