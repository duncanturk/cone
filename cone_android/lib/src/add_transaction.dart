import 'dart:async' show StreamSubscription;

import 'package:cone_lib/cone_lib.dart' show Posting, Transaction;
import 'package:flutter/material.dart' hide Actions;
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:redux/redux.dart' show Store;

import 'package:cone/src/localizations.dart' show ConeLocalizations;
import 'package:cone/src/redux/actions.dart'
    show
        Actions,
        RemovePostingAtAction,
        UpdateAccountAction,
        UpdateCommodityAction,
        UpdateDateAction,
        UpdateDescriptionAction,
        UpdateQuantityAction;
import 'package:cone/src/redux/state.dart' show ConeState;
import 'package:cone/src/reselect.dart';
import 'package:cone/src/services.dart';

class AddTransaction extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ConeState>(
      builder: (BuildContext context, Store<ConeState> store) {
        return Scaffold(
          appBar: AppBar(
            title: Text(ConeLocalizations.of(context).addTransaction),
          ),
          body: AddTransactionBody(),
          floatingActionButton: SaveButton(),
        );
      },
    );
  }
}

class AddTransactionBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<ConeState, bool>(
      converter: (Store<ConeState> store) => store.state.saveInProgress,
      builder: (BuildContext context, bool saveInProgress) {
        return Stack(
          children: <Widget>[
            Opacity(
              opacity: saveInProgress ? 0.5 : 1.0,
              child: AddTransactionForm(),
            ),
            if (saveInProgress)
              const ModalBarrier(
                dismissible: false,
              ),
            if (saveInProgress)
              const Center(child: CircularProgressIndicator()),
          ],
        );
      },
    );
  }
}

class AddTransactionForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ConeState>(
      builder: (BuildContext context, Store<ConeState> store) {
        if (needsNewPosting(store.state)) {
          store.dispatch(Actions.addPosting);
        }
        return ListView.builder(
          itemCount: store.state.transaction.postings.length + 1,
          itemBuilder: (BuildContext context, int index) => (index == 0)
              ? DateAndDescriptionWidget()
              : DismissiblePostingWidget(store: store, index: index - 1),
        );
      },
    );
  }
}

class DismissiblePostingWidget extends StatelessWidget {
  const DismissiblePostingWidget({this.store, this.index});

  final Store<ConeState> store;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey<int>(store.state.transaction.postings[index].key),
      onDismissed: (DismissDirection _) =>
          store.dispatch(RemovePostingAtAction(index)),
      child: PostingWidget(index),
    );
  }
}

class DateAndDescriptionWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: <Widget>[
          Container(
            width: 156,
            child: DateWidget(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: DescriptionWidget(),
            ),
          ),
        ],
      ),
    );
  }
}

class DateWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ConeState>(
      builder: (BuildContext context, Store<ConeState> store) {
        return DateField(store: store);
      },
    );
  }
}

class DateField extends StatefulWidget {
  const DateField({this.store});

  final Store<ConeState> store;

  @override
  DateFieldState createState() => DateFieldState();
}

class DateFieldState extends State<DateField> {
  final TextEditingController controller = TextEditingController();
  StreamSubscription<ConeState> subscription;
  String lastText = '';
  String converter(ConeState state) => state.transaction.date;

  @override
  void initState() {
    super.initState();

    controller.addListener(controllerListener);
    subscription = widget.store.onChange.listen(storeListener);
  }

  void controllerListener() {
    if (lastText == controller.text ||
        converter(widget.store.state) == controller.text) {
      return;
    }

    widget.store.dispatch(UpdateDateAction(controller.text));

    lastText = controller.text;
  }

  void storeListener(ConeState state) {
    if (controller.text == converter(widget.store.state)) {
      return;
    }
    setState(
      () {
        controller
          ..removeListener(controllerListener)
          ..text = converter(widget.store.state)
          ..addListener(controllerListener);
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ConeState>(
      builder: (BuildContext context, Store<ConeState> store) {
        return TextField(
          controller: controller,
          keyboardType: TextInputType.datetime,
          textInputAction: TextInputAction.next,
          onSubmitted: (dynamic _) => FocusScope.of(context).nextFocus(),
          decoration: InputDecoration(
            hintText: 'Today',
            border: const OutlineInputBorder(),
            filled: true,
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today),
              focusNode: FocusNode(skipTraversal: true),
              onPressed: () async {
                final DateTime result = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (result != null) {
                  controller.text =
                      reselectDateFormat(widget.store.state).format(result);
                }
                FocusScope.of(context).nextFocus();
              },
            ),
          ),
        );
      },
    );
  }
}

class DescriptionWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ConeState>(
      builder: (BuildContext context, Store<ConeState> store) {
        return DescriptionField(store: store);
      },
    );
  }
}

class DescriptionField extends StatefulWidget {
  const DescriptionField({this.store});

  final Store<ConeState> store;

  @override
  DescriptionFieldState createState() => DescriptionFieldState();
}

class DescriptionFieldState extends State<DescriptionField> {
  final TextEditingController controller = TextEditingController();
  StreamSubscription<ConeState> subscription;
  String lastText = '';
  String converter(ConeState state) => state.transaction.description;

  @override
  void initState() {
    super.initState();

    controller.addListener(controllerListener);
    subscription = widget.store.onChange.listen(storeListener);
  }

  void controllerListener() {
    if (lastText == controller.text ||
        converter(widget.store.state) == controller.text) {
      return;
    }

    widget.store.dispatch(UpdateDescriptionAction(controller.text));

    lastText = controller.text;
  }

  void storeListener(ConeState state) {
    if (controller.text == converter(widget.store.state)) {
      return;
    }
    setState(
      () {
        controller
          ..removeListener(controllerListener)
          ..text = converter(widget.store.state)
          ..addListener(controllerListener);
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ConeState>(
      builder: (BuildContext context, Store<ConeState> store) {
        return TypeAheadField<String>(
          getImmediateSuggestions: true,
          textFieldConfiguration: TextFieldConfiguration<dynamic>(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.next,
            onSubmitted: (dynamic _) => FocusScope.of(context).nextFocus(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              filled: true,
            ),
          ),
          itemBuilder: (BuildContext context, String suggestion) {
            return ListTile(title: Text(suggestion));
          },
          onSuggestionSelected: (String suggestion) {
            controller.text = suggestion;
          },
          suggestionsCallback: reselectDescriptionSuggestions(store.state),
          transitionBuilder:
              (BuildContext _, Widget suggestionsBox, AnimationController __) =>
                  suggestionsBox,
        );
      },
    );
  }
}

class PostingWidget extends StatelessWidget {
  const PostingWidget(this.index);

  final int index;

  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ConeState>(
      builder: (BuildContext context, Store<ConeState> store) {
        final bool currencyOnLeft = store.state.currencyOnLeft;
        final Widget accountWidget = Expanded(
          child: AccountField(store: store, index: index),
        );
        final Widget quantityWidget = Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Container(
            width: 80,
            child: QuantityField(store: store, index: index),
          ),
        );
        final Widget currencyWidget = Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Container(
            width: 40,
            child: CommodityField(store: store, index: index),
          ),
        );
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Row(
            children: <Widget>[
              accountWidget,
              if (currencyOnLeft) currencyWidget,
              quantityWidget,
              if (!currencyOnLeft) currencyWidget,
            ],
          ),
        );
      },
    );
  }
}

class AccountField extends StatefulWidget {
  const AccountField({this.store, this.index});

  final Store<ConeState> store;
  final int index;

  @override
  AccountFieldState createState() => AccountFieldState();
}

class AccountFieldState extends State<AccountField> {
  final TextEditingController controller = TextEditingController();
  StreamSubscription<ConeState> subscription;
  String lastText = '';
  String converter(ConeState state) =>
      state.transaction.postings[widget.index].account;

  @override
  void initState() {
    if (widget.index < widget.store.state.transaction.postings.length) {
      controller.addListener(controllerListener);
      subscription = widget.store.onChange.listen(storeListener);

      super.initState();
    }
  }

  void controllerListener() {
    if (lastText == controller.text ||
        converter(widget.store.state) == controller.text) {
      return;
    }
    widget.store.dispatch(
      UpdateAccountAction(index: widget.index, account: controller.text),
    );
    lastText = controller.text;
  }

  void storeListener(ConeState state) {
    if (widget.index < widget.store.state.transaction.postings.length) {
      if (controller.text == converter(widget.store.state)) {
        return;
      }
      setState(
        () {
          controller
            ..removeListener(controllerListener)
            ..text = converter(widget.store.state)
            ..addListener(controllerListener);
        },
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<String>(
      getImmediateSuggestions: true,
      textFieldConfiguration: TextFieldConfiguration<dynamic>(
        controller: controller,
        textInputAction: TextInputAction.next,
        onSubmitted: (dynamic _) => FocusScope.of(context).nextFocus(),
      ),
      itemBuilder: (BuildContext context, String suggestion) {
        return ListTile(title: Text(suggestion));
      },
      onSuggestionSelected: (String suggestion) {
        controller.text = suggestion;
      },
      suggestionsCallback: reselectAccountSuggestions(widget.store.state),
      transitionBuilder:
          (BuildContext _, Widget suggestionsBox, AnimationController __) =>
              suggestionsBox,
    );
  }
}

class QuantityField extends StatefulWidget {
  const QuantityField({this.store, this.index});

  final Store<ConeState> store;
  final int index;

  @override
  QuantityFieldState createState() => QuantityFieldState();
}

class QuantityFieldState extends State<QuantityField> {
  TextEditingController controller = TextEditingController();
  StreamSubscription<ConeState> subscription;
  String lastText = '';
  String hint;
  String converter(ConeState state) =>
      state.transaction.postings[widget.index].amount?.quantity;

  @override
  void initState() {
    super.initState();

    if (widget.index < widget.store.state.transaction.postings.length) {
      controller.addListener(controllerListener);
      subscription = widget.store.onChange.listen(storeListener);

      hint = quantityHint(widget.store.state);
    }
  }

  void controllerListener() {
    if (lastText == controller.text ||
        converter(widget.store.state) == controller.text) {
      return;
    }
    widget.store.dispatch(
      UpdateQuantityAction(index: widget.index, quantity: controller.text),
    );
    lastText = controller.text;
  }

  void storeListener(ConeState state) {
    if (widget.index < widget.store.state.transaction.postings.length) {
      if (controller.text == converter(widget.store.state)) {
        return;
      }
      setState(
        () {
          controller
            ..removeListener(controllerListener)
            ..text = converter(widget.store.state)
            ..addListener(controllerListener);
        },
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool lastField =
        widget.index == widget.store.state.transaction.postings.length - 1 &&
            widget.store.state.currencyOnLeft;
    return TextField(
      textAlign: TextAlign.center,
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
      ),
      keyboardType: TextInputType.number,
      textInputAction: lastField ? null : TextInputAction.next,
      onSubmitted: lastField ? null : (_) => FocusScope.of(context).nextFocus(),
    );
  }
}

class CommodityField extends StatefulWidget {
  const CommodityField({this.store, this.index});

  final Store<ConeState> store;
  final int index;

  @override
  CommodityFieldState createState() => CommodityFieldState();
}

class CommodityFieldState extends State<CommodityField> {
  TextEditingController controller = TextEditingController();
  StreamSubscription<ConeState> subscription;
  String lastText = '';
  String defaultCurrency;
  String converter(ConeState state) =>
      state.transaction.postings[widget.index].amount?.commodity;

  @override
  void initState() {
    if (widget.index < widget.store.state.transaction.postings.length) {
      controller.addListener(controllerListener);

      subscription = widget.store.onChange.listen(storeListener);
    }
    defaultCurrency = widget.store.state.defaultCurrency;
    super.initState();
  }

  void controllerListener() {
    if (lastText == controller.text ||
        converter(widget.store.state) == controller.text) {
      return;
    }
    widget.store.dispatch(
      UpdateCommodityAction(index: widget.index, commodity: controller.text),
    );
    lastText = controller.text;
  }

  void storeListener(ConeState state) {
    if (widget.index < widget.store.state.transaction.postings.length) {
      if (controller.text == converter(widget.store.state)) {
        return;
      }
      setState(
        () {
          controller
            ..removeListener(controllerListener)
            ..text = converter(widget.store.state)
            ..addListener(controllerListener);
        },
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool lastField =
        widget.index == widget.store.state.transaction.postings.length - 1 &&
            !widget.store.state.currencyOnLeft;
    return TextField(
      textAlign: TextAlign.center,
      controller: controller,
      decoration: InputDecoration(
        hintText: defaultCurrency,
      ),
      textInputAction: lastField ? null : TextInputAction.next,
      onSubmitted: lastField ? null : (_) => FocusScope.of(context).nextFocus(),
    );
  }
}

class SaveButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StoreBuilder<ConeState>(
      builder: (BuildContext context, Store<ConeState> store) {
        final bool readyForSave = makeSaveButtonAvailable(store.state);
        return FloatingActionButton(
          child: readyForSave
              ? const Icon(Icons.save)
              : Icon(Icons.save, color: Colors.grey[600]),
          onPressed: readyForSave
              ? () {
                  final Transaction transaction =
                      implicitTransaction(store.state);
                  appendFile(
                    store.state.ledgerFileUri,
                    '${implicitTransaction(store.state)}',
                  ).then((_) {
                    if (store.state.debugMode) {
                      Scaffold.of(context).showSnackBar(
                        transactionSnackBar(transaction: transaction),
                      );
                    } else {
                      Navigator.of(context).pop(transaction);
                    }
                  });
                }
              : null,
          backgroundColor: readyForSave ? null : Colors.grey[400],
        );
      },
    );
  }
}

SnackBar transactionSnackBar({Transaction transaction}) {
  return SnackBar(
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text.rich(
          TextSpan(
            text: transaction.date,
            children: <TextSpan>[
              TextSpan(text: ' ${transaction.description}'),
            ],
          ),
          style: const TextStyle(fontFamily: 'IBMPlexMono'),
        ),
        ...transaction.postings.map(
          (Posting posting) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text.rich(
                  TextSpan(text: '  ${posting.account}'),
                  style: const TextStyle(fontFamily: 'IBMPlexMono'),
                ),
                Text.rich(
                  TextSpan(text: '${posting.amount ?? ''}'),
                  style: const TextStyle(fontFamily: 'IBMPlexMono'),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}
