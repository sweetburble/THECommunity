import 'package:THECommu/common/common.dart';
import 'package:THECommu/common/util/debounce.dart';
import 'package:THECommu/common/widget/avartar_widget.dart';
import 'package:THECommu/data/models/user_model.dart';
import 'package:THECommu/riverpods/search/search_controller.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/**
 * 사용자 검색 기능에 Debounce를 적용한다 (한 글자 입력할 때마다 검색 로직이 실행되서 부하가 심하기 때문)
 * Debounce란? -> 대기 시간 + 요청 로직
 *
 * 직접 구현하거나, 외부 패키지로도 있다
 */
class SearchFragment extends StatefulHookConsumerWidget {
  const SearchFragment({super.key});

  @override
  ConsumerState<SearchFragment> createState() => _SearchFragmentState();
}

class _SearchFragmentState extends ConsumerState<SearchFragment> {
  final Debounce debounce = Debounce(milliseconds: 500); // 검색 로직에 0.5초 디바운스 적용

  @override
  void initState() {
    super.initState();
    _clearSearchState();
  }

  void _clearSearchState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchControllerProvider.notifier).clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<UserModel> userModelList = ref.watch(searchControllerProvider).userModelList;

    return SafeArea(
      child: Column(
        children: [
          height10,
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(),
              labelText: context.tr("user_search"),
            ),
            // 텍스트필드에 입력된 값이 바뀔 때마다, 아래 함수 호출
            onChanged: (value) {
              debounce.run(() async {
                if (value.trim().isNotEmpty) {
                  await ref.read(searchControllerProvider.notifier)
                      .searchUser(keyword: value);
                } else {
                  _clearSearchState();
                }
              });
            },
          ),
          height10,

          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: ListView.builder(
                  itemCount: userModelList.length,
                  itemBuilder: (context, index) {
                    UserModel userModel = userModelList[index];
                    // TODO: 유저 몇명 더 생성하고, 유저끼리 줄로 구분할지 결정
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
                      child: Row(
                        children: [
                          AvatarWidget(userModel: userModel, isTap: true),
                          width10,
                          Text(userModel.nickname, style: defaultFontStyle()),
                        ],
                      ),
                    );
                  },
              ),
            ),
          ),
        ],
      ).p(8),
    );
  }
}
