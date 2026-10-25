import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_assets/domain/entities/asset_holding.dart';
import 'package:simple_assets/presentation/providers/asset_providers.dart';

void main() {
  test('holdingByIdProvider 在无监听后自动释放', () async {
    final container = ProviderContainer(
      overrides: [
        allHoldingsProvider.overrideWith(
          (ref) => Stream.value(const <AssetHolding>[]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final provider = holdingByIdProvider(1);
    container.read(provider);
    await container.pump();

    expect(container.exists(provider), isFalse);
  });
}
