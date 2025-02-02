import 'package:epubx/example/epub_cfi/_parser.dart';
import 'package:html/dom.dart';

class EpubCfiInterpreter {
  Element? searchLocalPathForHref(
      Element? htmlElement, CfiLocalPath localPathNode) {
    // Interpret the first local_path node,
    // which is a set of steps and and a terminus condition
    CfiStep nextStepNode;
    var currentElement = htmlElement;

    for (var stepNum = 1; stepNum < localPathNode.steps!.length; stepNum++) {
      nextStepNode = localPathNode.steps![stepNum];
      if (nextStepNode.type == 'indexStep') {
        currentElement = interpretIndexStepNode(nextStepNode, currentElement);
      } else if (nextStepNode.type == 'indirectionStep') {
        currentElement =
            interpretIndirectionStepNode(nextStepNode, currentElement);
      }
    }

    return currentElement;
  }

  Element? interpretIndexStepNode(
      CfiStep? indexStepNode, Element? currentElement) {
    // Check node type; throw error if wrong type
    if (indexStepNode == null || indexStepNode.type != 'indexStep') {
      throw Exception('$indexStepNode: expected index step node');
    }

    // Index step
    final stepTarget = _getNextNode(indexStepNode.stepLength, currentElement);

    // Check the id assertion, if it exists
    if ((indexStepNode.idAssertion ?? '').isNotEmpty) {
      if (!_targetIdMatchesIdAssertion(
          stepTarget!, indexStepNode.idAssertion)) {
        throw Exception(
            // ignore: lines_longer_than_80_chars
            '${indexStepNode.idAssertion}: ${stepTarget.attributes['id']} Id assertion failed');
      }
    }

    return stepTarget;
  }

  Element? interpretIndirectionStepNode(
      CfiStep? indirectionStepNode, Element? currentElement) {
    // Check node type; throw error if wrong type
    if (indirectionStepNode == null ||
        indirectionStepNode.type != 'indirectionStep') {
      throw Exception('$indirectionStepNode: expected indirection step node');
    }

    // Indirection step
    final stepTarget =
        _getNextNode(indirectionStepNode.stepLength, currentElement);

    // Check the id assertion, if it exists
    if (indirectionStepNode.idAssertion != null) {
      if (!_targetIdMatchesIdAssertion(
          stepTarget!, indirectionStepNode.idAssertion)) {
        throw Exception(
            // ignore: lines_longer_than_80_chars
            '${indirectionStepNode.idAssertion}: ${stepTarget.attributes['id']} Id assertion failed');
      }
    }

    return stepTarget;
  }

  bool _targetIdMatchesIdAssertion(Element foundNode, String? idAssertion) =>
      foundNode.attributes.containsKey('id') &&
      foundNode.attributes['id'] == idAssertion;

  Element? _getNextNode(int cfiStepValue, Element? currentNode) {
    if (cfiStepValue % 2 == 0) {
      return _elementNodeStep(cfiStepValue, currentNode!);
    }

    return null;
  }

  Element _elementNodeStep(int cfiStepValue, Element currentNode) {
    final targetNodeIndex = ((cfiStepValue / 2) - 1).toInt();
    final numElements = currentNode.children.length;

    if (targetNodeIndex > numElements) {
      throw RangeError.range(targetNodeIndex, 0, numElements - 1);
    }

    return currentNode.children[targetNodeIndex];
  }
}
